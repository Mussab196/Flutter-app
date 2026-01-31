import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../providers/live_vision_provider.dart';

class LiveVisionScreen extends StatefulWidget {
  const LiveVisionScreen({super.key});

  @override
  State<LiveVisionScreen> createState() => _LiveVisionScreenState();
}

class _LiveVisionScreenState extends State<LiveVisionScreen> {
  // YOLOv8s model - properly exported from ultralytics
  // Model file: android/app/src/main/assets/yolov8s_float32.tflite (42.8 MB)
  static const String modelPath = 'yolov8s_float32'; // YOLOv8s Detection model

  // Detection state
  List<YOLOResult> _detections = [];
  bool _isModelLoaded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LiveVisionProvider>(context, listen: false);
      provider.initialize();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onDetection(List<YOLOResult> results) {
    // Debug logging
    print('🎯 YOLO Detection called: ${results.length} objects found');
    if (results.isEmpty) {
      print('⚠️ No objects detected in frame');
    } else {
      for (var result in results) {
        print(
            '  - ${result.className}: ${(result.confidence * 100).toStringAsFixed(1)}%');
      }
    }

    setState(() {
      _detections = results;
      _isModelLoaded = true;
    });

    // Update provider with detection results
    final provider = Provider.of<LiveVisionProvider>(context, listen: false);
    provider.onDetectionResults(results);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveVisionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: SafeArea(
            child: Column(
              children: [
                // Header AppBar
                _buildHeader(context),

                // Main Camera View with YOLO
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey.shade800,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // YOLO Camera View
                          _buildCameraView(provider),

                          // LIVE Indicator
                          _buildLiveIndicator(provider),

                          // Detection Boxes Overlay
                          ..._buildDetectionBoxes(),

                          // Description Card
                          _buildDescriptionCard(provider),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.95, 0.95)),

                // Bottom Action Buttons
                _buildBottomActions(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            'Live Vision',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Model loading indicator
          if (!_isModelLoaded)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.cyan,
              ),
            ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.grid_view, color: Colors.white54, size: 22),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white54, size: 22),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCameraView(LiveVisionProvider provider) {
    if (_loadError != null) {
      return Container(
        color: const Color(0xFF0D0D0D),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Model Error',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please ensure yolov8n.tflite model is placed in android/app/src/main/assets/',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    print('📦 Loading YOLO model from: $modelPath');
    return YOLOView(
      modelPath: modelPath,
      task: YOLOTask.detect,
      onResult: _onDetection,
    );
  }

  Widget _buildLiveIndicator(LiveVisionProvider provider) {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: provider.isPaused ? Colors.orange : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                provider.isPaused ? 'PAUSED' : 'LIVE',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              if (_detections.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_detections.length} objects',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.cyan,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn()
        .then(delay: 1000.ms)
        .fadeOut(duration: 500.ms);
  }

  List<Widget> _buildDetectionBoxes() {
    return _detections.map((detection) {
      // Get color based on confidence
      Color boxColor = _getConfidenceColor(detection.confidence);

      return Positioned(
        left: detection.boundingBox.left,
        top: detection.boundingBox.top,
        width: detection.boundingBox.width,
        height: detection.boundingBox.height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: boxColor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: boxColor.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    '${detection.className} ${(detection.confidence * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9));
    }).toList();
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.cyan;
    } else if (confidence >= 0.4) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildDescriptionCard(LiveVisionProvider provider) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => provider.announceScene(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    provider.isSpeaking ? Icons.volume_up : Icons.touch_app,
                    size: 16,
                    color: provider.isSpeaking ? Colors.cyan : Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.isSpeaking
                        ? 'Speaking...'
                        : 'Tap to hear description',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                provider.sceneDescription.isNotEmpty
                    ? provider.sceneDescription
                    : 'Point camera at objects to detect them.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildBottomActions(
      BuildContext context, LiveVisionProvider provider) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pause Button
          _buildActionButton(
            icon: provider.isPaused ? Icons.play_arrow : Icons.pause,
            onTap: () => provider.togglePause(),
            backgroundColor: Colors.grey.shade800,
          ),
          const SizedBox(width: 14),
          // Speaker Button
          _buildActionButton(
            icon: provider.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            onTap: () => provider.toggleSpeaker(),
            backgroundColor: provider.isSpeakerOn
                ? Colors.cyan.shade700
                : Colors.grey.shade800,
          ),
          const SizedBox(width: 14),
          // Close Button
          _buildActionButton(
            icon: Icons.close,
            onTap: () {
              provider.stop();
              context.go('/home');
            },
            backgroundColor: Colors.red.shade600,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3);
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
