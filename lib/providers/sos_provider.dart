import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../data/models/emergency_contact_model.dart';

/// SOS/Emergency Provider, Manages emergency contacts and SOS functionality
/// Uses Platform Channel for direct SMS sending (no app opening)
/// Works offline with local storage, syncs to Firebase when available
class SosProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Platform channel for native SMS
  static const _smsChannel = MethodChannel('com.visionaid/sms');

  // Flag to track if Firebase is available
  bool _firebaseAvailable = false;

  List<EmergencyContactModel> _contacts = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  Position? _currentPosition;
  List<Map<String, dynamic>> _sosHistory = [];
  int _smsSentCount = 0;

  // Getters
  List<EmergencyContactModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;
  List<Map<String, dynamic>> get sosHistory => _sosHistory;
  int get smsSentCount => _smsSentCount;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Initialize provider - load contacts
  SosProvider() {
    loadContacts();
  }

  /// Load contacts - tries Firebase first, falls back to local storage
  Future<void> loadContacts() async {
    _isLoading = true;
    notifyListeners();

    // Try loading from local storage first (faster)
    await _loadContactsFromLocal();

    // Then try Firebase in background
    if (_userId != null) {
      _tryLoadFromFirebase();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load contacts from SharedPreferences
  Future<void> _loadContactsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('emergency_contacts');

      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        _contacts =
            decoded.map((e) => EmergencyContactModel.fromJson(e)).toList();
      } else {
        _loadDefaultContacts();
        await _saveContactsToLocal();
      }
    } catch (e) {
      debugPrint('Error loading local contacts: $e');
      _loadDefaultContacts();
    }
  }

  /// Save contacts to SharedPreferences
  Future<void> _saveContactsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson =
          jsonEncode(_contacts.map((c) => c.toJson()).toList());
      await prefs.setString('emergency_contacts', contactsJson);
    } catch (e) {
      debugPrint('Error saving local contacts: $e');
    }
  }

  /// Try to load from Firebase (non-blocking)
  Future<void> _tryLoadFromFirebase() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('emergency_contacts')
          .orderBy('createdAt', descending: false)
          .get()
          .timeout(const Duration(seconds: 5));

      _firebaseAvailable = true;

      if (snapshot.docs.isNotEmpty) {
        _contacts = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return EmergencyContactModel.fromJson(data);
        }).toList();
        await _saveContactsToLocal();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Firebase not available: $e');
      _firebaseAvailable = false;
    }
  }

  /// Load default emergency contacts
  void _loadDefaultContacts() {
    _contacts = [
      EmergencyContactModel(
        id: '1',
        name: 'Mom',
        phone: '+923001234567',
        role: 'Family',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFE74C3C),
      ),
      EmergencyContactModel(
        id: '2',
        name: 'Dad',
        phone: '+923009876543',
        role: 'Family',
        icon: Icons.person_rounded,
        color: const Color(0xFF00B894),
      ),
      EmergencyContactModel(
        id: '3',
        name: 'Emergency',
        phone: '1122',
        role: 'Emergency',
        icon: Icons.local_hospital_rounded,
        color: const Color(0xFF4A90D9),
      ),
    ];
  }

  /// Save contact to Firebase
  Future<String?> _saveContactToFirebase(EmergencyContactModel contact) async {
    if (_userId == null) return null;

    try {
      final data = contact.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('emergency_contacts')
          .add(data);

      return docRef.id;
    } catch (e) {
      debugPrint('Error saving contact: $e');
      return null;
    }
  }

  /// Check if SMS permission is granted
  Future<bool> hasSmsPermission() async {
    try {
      final result = await _smsChannel.invokeMethod('hasPermission');
      return result == true;
    } catch (e) {
      debugPrint('Error checking SMS permission: $e');
      return false;
    }
  }

  /// Request SMS permission
  Future<void> requestSmsPermission() async {
    try {
      await _smsChannel.invokeMethod('requestPermission');
    } catch (e) {
      debugPrint('Error requesting SMS permission: $e');
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permission denied';
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permission permanently denied';
        notifyListeners();
        return null;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return _currentPosition;
    } catch (e) {
      _errorMessage = 'Failed to get location: $e';
      notifyListeners();
      return null;
    }
  }

  /// Send SMS directly using platform channel (no app opens)
  Future<bool> _sendSmsDirectly(String phoneNumber, String message) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      final result = await _smsChannel.invokeMethod('sendSms', {
        'phone': cleanNumber,
        'message': message,
      });

      return result == true;
    } catch (e) {
      debugPrint('Failed to send SMS to $phoneNumber: $e');
      return false;
    }
  }

  /// Send SOS Alert - Sends SMS directly to all contacts
  Future<bool> sendSosAlert({String? customMessage}) async {
    _isSending = true;
    _errorMessage = null;
    _smsSentCount = 0;
    notifyListeners();

    try {
      // Vibrate for feedback
      HapticFeedback.heavyImpact();

      // Check SMS permission
      final hasPermission = await hasSmsPermission();
      if (!hasPermission) {
        await requestSmsPermission();
        // Wait a bit for permission dialog
        await Future.delayed(const Duration(seconds: 2));

        final permissionGranted = await hasSmsPermission();
        if (!permissionGranted) {
          _errorMessage = 'SMS permission denied';
          _isSending = false;
          notifyListeners();
          return false;
        }
      }

      // Get current location
      final position = await getCurrentLocation();

      // Create SOS message
      String message = '🆘 EMERGENCY SOS!\n';
      message += customMessage ?? 'I need immediate help!\n';

      if (position != null) {
        message +=
            '📍 Location: https://maps.google.com/?q=${position.latitude},${position.longitude}';
      }

      // Send SMS to all contacts
      int successCount = 0;
      for (var contact in _contacts) {
        if (contact.phone.isNotEmpty) {
          final sent = await _sendSmsDirectly(contact.phone, message);
          if (sent) {
            successCount++;
            debugPrint('✅ SMS sent to ${contact.name}');
          } else {
            debugPrint('❌ Failed to send SMS to ${contact.name}');
          }
          // Small delay between messages
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      _smsSentCount = successCount;

      // Save to Firebase (ignore errors)
      _saveSosAlertToFirebase(
        latitude: position?.latitude,
        longitude: position?.longitude,
        message: message,
        recipients: _contacts.map((c) => c.phone).toList(),
        smsSentCount: successCount,
      );

      // Vibrate success
      if (successCount > 0) {
        HapticFeedback.mediumImpact();
      }

      _isSending = false;
      notifyListeners();
      return successCount > 0;
    } catch (e) {
      _errorMessage = 'Failed to send SOS: $e';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Save SOS alert to Firebase for history
  Future<void> _saveSosAlertToFirebase({
    double? latitude,
    double? longitude,
    String? message,
    List<String>? recipients,
    int? smsSentCount,
  }) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sos_history')
          .add({
        'latitude': latitude,
        'longitude': longitude,
        'message': message,
        'recipients': recipients,
        'smsSentCount': smsSentCount,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });
    } catch (e) {
      debugPrint('Error saving SOS alert: $e');
    }
  }

  /// Add new contact and save locally (and to Firebase if available)
  Future<void> addContact(EmergencyContactModel contact) async {
    _contacts.add(contact);
    await _saveContactsToLocal();
    notifyListeners();

    // Try to save to Firebase in background
    if (_userId != null && _firebaseAvailable) {
      try {
        final data = contact.toJson();
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();

        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('emergency_contacts')
            .add(data)
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Firebase save failed (offline): $e');
      }
    }
  }

  /// Remove contact locally (and from Firebase if available)
  Future<void> removeContact(String contactId) async {
    _contacts.removeWhere((c) => c.id == contactId);
    await _saveContactsToLocal();
    notifyListeners();

    // Try to delete from Firebase in background
    if (_userId != null && _firebaseAvailable) {
      try {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('emergency_contacts')
            .doc(contactId)
            .delete()
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Firebase delete failed (offline): $e');
      }
    }
  }

  /// Update contact locally (and in Firebase if available)
  Future<void> updateContact(
      String contactId, EmergencyContactModel updatedContact) async {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = updatedContact.copyWith(id: contactId);
      await _saveContactsToLocal();
      notifyListeners();
    }

    // Try to update Firebase in background
    if (_userId != null && _firebaseAvailable) {
      try {
        final data = updatedContact.toJson();
        data['updatedAt'] = FieldValue.serverTimestamp();

        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('emergency_contacts')
            .doc(contactId)
            .update(data)
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Firebase update failed (offline): $e');
      }
    }
  }

  /// Load SOS history from Firebase (if available)
  Future<void> loadSosHistory() async {
    if (_userId == null || !_firebaseAvailable) {
      _sosHistory = [];
      notifyListeners();
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sos_history')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 5));

      _sosHistory = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading SOS history: $e');
      _sosHistory = [];
      notifyListeners();
    }
  }

  /// Make phone call to a contact
  Future<void> makeCall(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final telUri = Uri.parse('tel:$cleanNumber');

      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      }
    } catch (e) {
      debugPrint('Failed to make call: $e');
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh contacts from Firebase
  Future<void> refreshContacts() async {
    await loadContacts();
  }
}
