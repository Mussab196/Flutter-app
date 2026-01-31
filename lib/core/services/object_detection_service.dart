import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

/// Detection result class
class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  String get displayConfidence => '${(confidence * 100).toStringAsFixed(0)}%';

  @override
  String toString() => '$label ($displayConfidence)';
}

/// Object Detection Service using Google ML Kit
class ObjectDetectionService {
  ObjectDetector? _objectDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the object detector
  Future<void> initialize() async {
    try {
      print('🔄 Initializing ML Kit Object Detector...');

      // Use default model with all classifications
      final options = ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      );

      _objectDetector = ObjectDetector(options: options);
      _isInitialized = true;
      print('✅ ML Kit Object Detector initialized');
    } catch (e) {
      print('❌ Failed to initialize detector: $e');
      _isInitialized = false;
    }
  }

  /// Detect objects from camera image
  Future<List<DetectionResult>> detectFromCameraImage(
    CameraImage image,
    int sensorOrientation,
    CameraLensDirection lensDirection,
  ) async {
    if (!_isInitialized || _objectDetector == null) return [];

    try {
      final inputImage =
          _convertCameraImage(image, sensorOrientation, lensDirection);
      if (inputImage == null) return [];

      final objects = await _objectDetector!.processImage(inputImage);
      return _processResults(objects);
    } catch (e) {
      print('❌ Detection error: $e');
      return [];
    }
  }

  /// Detect objects from file
  Future<List<DetectionResult>> detectFromFile(String filePath) async {
    if (!_isInitialized || _objectDetector == null) return [];

    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final objects = await _objectDetector!.processImage(inputImage);
      return _processResults(objects);
    } catch (e) {
      print('❌ File detection error: $e');
      return [];
    }
  }

  /// Convert camera image to InputImage
  InputImage? _convertCameraImage(
    CameraImage image,
    int sensorOrientation,
    CameraLensDirection lensDirection,
  ) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;
      final bytes = plane.bytes;

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      if (rotation == null) return null;

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      print('❌ Image conversion error: $e');
      return null;
    }
  }

  /// Process detection results
  List<DetectionResult> _processResults(List<DetectedObject> objects) {
    final results = <DetectionResult>[];

    for (final obj in objects) {
      if (obj.labels.isNotEmpty) {
        // Get the best label
        final bestLabel = obj.labels.reduce(
          (a, b) => a.confidence > b.confidence ? a : b,
        );

        // Map generic labels to more specific names
        final label = _mapLabel(bestLabel.text);

        results.add(DetectionResult(
          label: label,
          confidence: bestLabel.confidence,
          boundingBox: obj.boundingBox,
        ));
      }
    }

    // Sort by confidence
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  /// Map generic ML Kit labels to more user-friendly names
  String _mapLabel(String label) {
    final mappings = {
      'Fashion good': 'Clothing item',
      'Home good': 'Household item',
      'Food': 'Food item',
      'Place': 'Location/Place',
      'Plant': 'Plant',
      'Animal': 'Animal',
      'Person': 'Person',
      'Electronic': 'Electronic device',
      'Furniture': 'Furniture',
      'Vehicle': 'Vehicle',
    };

    return mappings[label] ?? label;
  }

  /// Dispose resources
  void dispose() {
    _objectDetector?.close();
    _objectDetector = null;
    _isInitialized = false;
  }
}
