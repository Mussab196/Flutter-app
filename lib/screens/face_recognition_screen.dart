import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  bool isRecognizing = true;
  Map<String, String>? recognizedFace;

  @override
  void initState() {
    super.initState();
    // Simulate recognition
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          recognizedFace = {
            'name': 'Sarah',
            'relationship': 'Your sister',
            'position': 'on the left',
          };
          isRecognizing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      'Face Recognition',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/add-face'),
                    icon: const Icon(Icons.person_add_outlined,
                        color: Colors.white70),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Camera Preview - Circular
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size =
                        (constraints.maxWidth * 0.55).clamp(180.0, 240.0);
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0D0D0D),
                        border: Border.all(
                          color: Colors.grey.shade800,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Stack(
                          children: [
                            // Camera background
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: const Color(0xFF0D0D0D),
                            ),

                            // Grid lines
                            CustomPaint(
                              size: Size(size, size),
                              painter: CircleGridPainter(),
                            ),

                            // LIVE Indicator
                            Positioned(
                              top: 60,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'LIVE',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .fadeIn()
                                .then(delay: 1000.ms)
                                .fadeOut(duration: 500.ms),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.9, 0.9),
                  ),
            ),

            // Recognition Result Card
            if (recognizedFace != null)
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recognizedFace!['name']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${recognizedFace!['relationship']!} • ${recognizedFace!['position']!}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.cyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

            // Manage Saved Faces Button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to manage faces
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Manage Saved Faces',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

// Custom painter for circular grid
class CircleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade800.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw vertical lines
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final dx = x - center.dx;
      if (dx.abs() < radius) {
        final dy = (radius * radius - dx * dx);
        if (dy > 0) {
          final sqrtDy = dy > 0 ? dy.toDouble() : 0.0;
          final y1 = center.dy - (sqrtDy > 0 ? sqrtDy.toDouble().abs() : 0.0);
          final y2 = center.dy + (sqrtDy > 0 ? sqrtDy.toDouble().abs() : 0.0);
          canvas.drawLine(
            Offset(x, y1 > 0 ? (y1 * 0.5 + size.height * 0.25) : 0),
            Offset(
                x,
                y2 < size.height
                    ? (y2 * 0.5 + size.height * 0.25)
                    : size.height),
            paint,
          );
        }
      }
    }

    // Draw horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      final dy = y - center.dy;
      if (dy.abs() < radius) {
        final dx = (radius * radius - dy * dy);
        if (dx > 0) {
          final sqrtDx = dx > 0 ? dx.toDouble() : 0.0;
          final x1 = center.dx - (sqrtDx > 0 ? sqrtDx.toDouble().abs() : 0.0);
          final x2 = center.dx + (sqrtDx > 0 ? sqrtDx.toDouble().abs() : 0.0);
          canvas.drawLine(
            Offset(x1 > 0 ? (x1 * 0.5 + size.width * 0.25) : 0, y),
            Offset(
                x2 < size.width ? (x2 * 0.5 + size.width * 0.25) : size.width,
                y),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
