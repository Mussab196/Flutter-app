import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// Detection result for a single object
class DetectedObjectInfo {
  final String label;
  final double confidence;
  final Rect boundingBox;

  DetectedObjectInfo({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  String get displayConfidence => '${(confidence * 100).toStringAsFixed(0)}%';
}

/// Live Vision Provider - Manages ML Kit object detection and TTS
class LiveVisionProvider extends ChangeNotifier {
  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();

  // State
  bool _isInitialized = false;
  bool _isPaused = false;
  bool _isSpeakerOn = true;
  bool _isSpeaking = false;
  String? _errorMessage;

  // Detection results
  List<DetectedObjectInfo> _detectedObjects = [];
  String _sceneDescription = '';

  // Announce settings
  DateTime? _lastAnnouncement;
  static const Duration _announcementCooldown = Duration(seconds: 3);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPaused => _isPaused;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isSpeaking => _isSpeaking;
  String? get errorMessage => _errorMessage;
  List<DetectedObjectInfo> get detectedObjects => _detectedObjects;
  String get sceneDescription => _sceneDescription;

  /// Initialize the provider
  Future<void> initialize() async {
    try {
      await _initTts();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      notifyListeners();
    }
  }

  /// Initialize Text-to-Speech
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      _errorMessage = 'TTS Error: $msg';
      notifyListeners();
    });
  }

  /// Generate a natural language description of the scene
  void _generateSceneDescription() {
    if (_detectedObjects.isEmpty) {
      _sceneDescription = 'No objects detected in view.';
      return;
    }

    // Group objects by label
    Map<String, int> objectCounts = {};
    Map<String, double> objectConfidences = {};

    for (var obj in _detectedObjects) {
      objectCounts[obj.label] = (objectCounts[obj.label] ?? 0) + 1;
      if ((objectConfidences[obj.label] ?? 0) < obj.confidence) {
        objectConfidences[obj.label] = obj.confidence;
      }
    }

    // Build description
    List<String> descriptions = [];
    objectCounts.forEach((label, count) {
      if (count == 1) {
        descriptions.add('a $label');
      } else {
        descriptions.add('$count ${label}s');
      }
    });

    if (descriptions.length == 1) {
      _sceneDescription = 'I can see ${descriptions[0]}.';
    } else if (descriptions.length == 2) {
      _sceneDescription =
          'I can see ${descriptions[0]} and ${descriptions[1]}.';
    } else {
      final lastItem = descriptions.removeLast();
      _sceneDescription =
          'I can see ${descriptions.join(", ")}, and $lastItem.';
    }
  }

  /// Announce the scene description via TTS
  void _announceIfNeeded() {
    if (!_isSpeakerOn || _isPaused || _isSpeaking) return;

    final now = DateTime.now();
    if (_lastAnnouncement != null &&
        now.difference(_lastAnnouncement!) < _announcementCooldown) {
      return;
    }

    if (_sceneDescription.isNotEmpty &&
        _sceneDescription != 'No objects detected in view.') {
      _speak(_sceneDescription);
      _lastAnnouncement = now;
    }
  }

  /// Speak text using TTS
  Future<void> _speak(String text) async {
    if (!_isSpeakerOn) return;
    await _flutterTts.speak(text);
  }

  /// Toggle pause state
  void togglePause() {
    _isPaused = !_isPaused;
    if (_isPaused) {
      _flutterTts.stop();
    }
    notifyListeners();
  }

  /// Toggle speaker
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    if (!_isSpeakerOn) {
      _flutterTts.stop();
    }
    notifyListeners();
  }

  /// Manually trigger scene description announcement
  Future<void> announceScene() async {
    if (_sceneDescription.isNotEmpty) {
      await _speak(_sceneDescription);
    }
  }

  /// Announce Gemini detection results
  Future<void> announceGeminiDetections(List<String> labels) async {
    if (!_isSpeakerOn || _isPaused) return;

    if (labels.isEmpty) {
      await _speak('No objects detected.');
      return;
    }

    // Build natural description
    String description;
    if (labels.length == 1) {
      description = 'I can see ${labels[0]}.';
    } else if (labels.length == 2) {
      description = 'I can see ${labels[0]} and ${labels[1]}.';
    } else {
      final lastItem = labels.removeLast();
      description = 'I can see ${labels.join(", ")}, and $lastItem.';
    }

    _sceneDescription = description;
    notifyListeners();

    await _speak(description);
  }

  /// Handle YOLO detection results from YOLOView
  void onDetectionResults(List<YOLOResult> results) {
    // Convert YOLO results to our internal format
    _detectedObjects = results
        .map((result) => DetectedObjectInfo(
              label: result.className,
              confidence: result.confidence,
              boundingBox: result.boundingBox,
            ))
        .toList();

    // Generate scene description
    _generateSceneDescription();

    // Announce if needed
    _announceIfNeeded();

    notifyListeners();
  }

  /// Stop all operations
  Future<void> stop() async {
    await _flutterTts.stop();
    _isPaused = true;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
