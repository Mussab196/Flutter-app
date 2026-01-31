import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Database Service
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ USER OPERATIONS ============

  /// Get user by ID
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Update user data
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ============ EMERGENCY CONTACTS ============

  /// Get emergency contacts for user
  Future<List<Map<String, dynamic>>> getEmergencyContacts(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('emergency_contacts')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add emergency contact
  Future<String?> addEmergencyContact(
      String uid, Map<String, dynamic> contact) async {
    try {
      contact['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('emergency_contacts')
          .add(contact);
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Update emergency contact
  Future<void> updateEmergencyContact(
    String uid,
    String contactId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('emergency_contacts')
        .doc(contactId)
        .update(data);
  }

  /// Delete emergency contact
  Future<void> deleteEmergencyContact(String uid, String contactId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('emergency_contacts')
        .doc(contactId)
        .delete();
  }

  // ============ SOS HISTORY ============

  /// Save SOS alert
  Future<String?> saveSosAlert(String uid, Map<String, dynamic> alert) async {
    try {
      alert['createdAt'] = FieldValue.serverTimestamp();
      alert['uid'] = uid;
      final docRef = await _firestore.collection('sos_alerts').add(alert);
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Get SOS history
  Future<List<Map<String, dynamic>>> getSosHistory(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('sos_alerts')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ============ OCR HISTORY ============

  /// Save OCR scan result
  Future<String?> saveOcrScan(String uid, Map<String, dynamic> scan) async {
    try {
      scan['createdAt'] = FieldValue.serverTimestamp();
      scan['uid'] = uid;
      final docRef = await _firestore.collection('ocr_scans').add(scan);
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Get OCR history
  Future<List<Map<String, dynamic>>> getOcrHistory(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('ocr_scans')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ============ SAVED FACES ============

  /// Save face data
  Future<String?> saveFace(String uid, Map<String, dynamic> face) async {
    try {
      face['createdAt'] = FieldValue.serverTimestamp();
      face['uid'] = uid;
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_faces')
          .add(face);
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Get saved faces
  Future<List<Map<String, dynamic>>> getSavedFaces(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_faces')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete saved face
  Future<void> deleteFace(String uid, String faceId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('saved_faces')
        .doc(faceId)
        .delete();
  }

  // ============ SETTINGS ============

  /// Get user settings
  Future<Map<String, dynamic>?> getSettings(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('preferences')
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Save user settings
  Future<void> saveSettings(String uid, Map<String, dynamic> settings) async {
    settings['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .set(settings, SetOptions(merge: true));
  }
}
