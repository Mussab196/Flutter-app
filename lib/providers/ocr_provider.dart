import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

/// OCR Provider - Manages text recognition and text-to-speech
class OcrProvider extends ChangeNotifier {
  // Use default script for better multi-language support
  final TextRecognizer _textRecognizer = TextRecognizer();
  final FlutterTts _flutterTts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();

  String _recognizedText = '';
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String? _errorMessage;
  File? _capturedImage;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isDisposed = false;
  Completer<void>? _currentOperation;

  // Getters
  String get recognizedText => _recognizedText;
  bool get isProcessing => _isProcessing;
  bool get isSpeaking => _isSpeaking;
  String? get errorMessage => _errorMessage;
  File? get capturedImage => _capturedImage;
  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isDisposed => _isDisposed;

  /// Initialize TTS
  Future<void> initTts() async {
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

  /// Initialize camera with maximum resolution for better OCR
  Future<void> initCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.max, // Maximum resolution for best OCR accuracy
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();

        // Enable auto-focus for sharper text
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.setFocusMode(FocusMode.auto);
          await _cameraController!.setExposureMode(ExposureMode.auto);
        }

        _isCameraInitialized = true;
        notifyListeners();
      } else {
        _errorMessage = 'No camera available';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      notifyListeners();
    }
  }

  /// Dispose camera
  void disposeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
  }

  /// Cancel ongoing operations
  void cancelOperations() {
    _isProcessing = false;
    _currentOperation = null;
    stopSpeaking();
  }

  /// Capture image from camera
  Future<File?> captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _errorMessage = 'Camera not initialized';
      notifyListeners();
      return null;
    }

    try {
      _isProcessing = true;
      notifyListeners();

      final XFile image = await _cameraController!.takePicture();
      _capturedImage = File(image.path);

      notifyListeners();
      return _capturedImage;
    } catch (e) {
      _errorMessage = 'Failed to capture image: $e';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        _capturedImage = File(image.path);
        notifyListeners();
        return _capturedImage;
      }
      return null;
    } catch (e) {
      _errorMessage = 'Failed to pick image: $e';
      notifyListeners();
      return null;
    }
  }

  /// Recognize text from image - preserving original text as-is
  Future<String> recognizeText(File imageFile) async {
    if (_isDisposed) return '';

    _isProcessing = true;
    _errorMessage = null;
    _currentOperation = Completer<void>();
    notifyListeners();

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (_isDisposed || _currentOperation == null) return '';

      // Sort text blocks by position (top to bottom, left to right)
      final sortedBlocks = _sortTextBlocksByPosition(recognizedText.blocks);

      // Build properly ordered text - PRESERVE AS-IS
      final StringBuffer orderedText = StringBuffer();

      for (final block in sortedBlocks) {
        if (_isDisposed) return '';

        // Sort lines within block
        final sortedLines = block.lines.toList()
          ..sort((a, b) {
            final yDiff = a.boundingBox.top.compareTo(b.boundingBox.top);
            if (yDiff != 0) return yDiff;
            return a.boundingBox.left.compareTo(b.boundingBox.left);
          });

        for (final line in sortedLines) {
          // Use original text as-is, only trim whitespace
          final text = line.text.trim();
          if (text.isNotEmpty) {
            orderedText.writeln(text);
          }
        }
        orderedText.writeln(); // Paragraph break between blocks
      }

      _recognizedText = orderedText.toString().trim();
      _isProcessing = false;
      _currentOperation = null;

      if (!_isDisposed) notifyListeners();

      return _recognizedText;
    } catch (e) {
      if (_isDisposed) return '';
      _errorMessage = 'Failed to recognize text: $e';
      _isProcessing = false;
      _currentOperation = null;
      notifyListeners();
      return '';
    }
  }

  /// Sort text blocks by position (top-to-bottom, left-to-right)
  List<TextBlock> _sortTextBlocksByPosition(List<TextBlock> blocks) {
    final sortedBlocks = blocks.toList();

    // Group blocks by approximate rows
    sortedBlocks.sort((a, b) {
      final aTop = a.boundingBox.top;
      final bTop = b.boundingBox.top;
      final aLeft = a.boundingBox.left;
      final bLeft = b.boundingBox.left;

      // If blocks are on roughly same line (within 30px threshold)
      if ((aTop - bTop).abs() < 30) {
        return aLeft.compareTo(bLeft); // Sort by left position
      }
      return aTop.compareTo(bTop); // Sort by top position
    });

    return sortedBlocks;
  }

  /// Capture and recognize text
  Future<String> captureAndRecognize() async {
    if (_isDisposed) return '';

    final image = await captureImage();

    if (image != null && !_isDisposed) {
      return await recognizeText(image);
    }

    _isProcessing = false;
    return '';
  }

  /// Speak text
  Future<void> speakText(String text) async {
    if (_isDisposed) return;

    if (text.isEmpty) {
      _errorMessage = 'No text to speak';
      notifyListeners();
      return;
    }

    try {
      _isSpeaking = true;
      notifyListeners();

      await _flutterTts.speak(text);
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = 'Failed to speak: $e';
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Pause speaking
  Future<void> pauseSpeaking() async {
    await _flutterTts.pause();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Speak recognized text
  Future<void> speakRecognizedText() async {
    if (_recognizedText.isNotEmpty) {
      await speakText(_recognizedText);
    } else {
      _errorMessage = 'No text recognized yet';
      notifyListeners();
    }
  }

  /// Clear recognized text
  void clearText() {
    _recognizedText = '';
    _capturedImage = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.1, 1.0));
  }

  /// Set speech volume
  Future<void> setSpeechVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Dispose resources
  @override
  void dispose() {
    _isDisposed = true;
    _currentOperation = null;
    _isProcessing = false;
    _flutterTts.stop();
    _textRecognizer.close();
    disposeCamera();
    super.dispose();
  }
}
