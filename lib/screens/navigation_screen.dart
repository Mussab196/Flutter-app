import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  bool voiceGuidanceEnabled = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final compassSize = size.width * 0.55;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Navigation Assist',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Compass View
            Expanded(
              child: Center(
                child: Container(
                  width: compassSize.clamp(180.0, 260.0),
                  height: compassSize.clamp(180.0, 260.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade900.withOpacity(0.5),
                    border: Border.all(
                      color: Colors.grey.shade800,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: CompassPainter(),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.cyan, Colors.blue],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.9, 0.9),
                    curve: Curves.easeOutCubic,
                  ),
            ),

            // Bottom Info Section - Scrollable
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.grey.shade800,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Obstacle Alert
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade800),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.warning_rounded,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Obstacle Detected',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Object ahead at 1.2 meters',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '1.2m',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      // Navigation Instructions
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Directions',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white,
                                  height: 1.6,
                                ),
                                children: const [
                                  TextSpan(text: 'Walk '),
                                  TextSpan(
                                    text: 'straight',
                                    style: TextStyle(
                                      color: Colors.cyan,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: ' for 3 meters, then turn '),
                                  TextSpan(
                                    text: 'left',
                                    style: TextStyle(
                                      color: Colors.cyan,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: '. A '),
                                  TextSpan(
                                    text: 'chair',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: ' is on your '),
                                  TextSpan(
                                    text: 'right',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      // Voice Guidance Toggle
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: voiceGuidanceEnabled
                                    ? Colors.cyan.withOpacity(0.2)
                                    : Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                voiceGuidanceEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                color: voiceGuidanceEnabled
                                    ? Colors.cyan
                                    : Colors.grey,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Voice Guidance',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    voiceGuidanceEnabled
                                        ? 'Active'
                                        : 'Disabled',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: voiceGuidanceEnabled,
                              onChanged: (value) {
                                setState(() {
                                  voiceGuidanceEnabled = value;
                                });
                              },
                              activeColor: Colors.cyan,
                              activeTrackColor: Colors.cyan.withOpacity(0.3),
                              inactiveThumbColor: Colors.grey.shade600,
                              inactiveTrackColor: Colors.grey.shade800,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Compass painter
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw inner circle
    final innerPaint = Paint()
      ..color = Colors.grey.shade800.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.6, innerPaint);

    // Draw compass lines
    final linePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - radius + 40, center.dy),
      Offset(center.dx + radius - 40, center.dy),
      linePaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius + 40),
      Offset(center.dx, center.dy + radius - 40),
      linePaint,
    );

    // Draw direction labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // N (highlight)
    textPainter.text = TextSpan(
      text: 'N',
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.cyan,
        fontWeight: FontWeight.w700,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, 8),
    );

    // S
    textPainter.text = TextSpan(
      text: 'S',
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, size.height - 24),
    );

    // W
    textPainter.text = TextSpan(
      text: 'W',
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(8, center.dy - textPainter.height / 2),
    );

    // E
    textPainter.text = TextSpan(
      text: 'E',
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - 20, center.dy - textPainter.height / 2),
    );

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final innerRadius = radius - (isCardinal ? 25 : 15);
      final outerRadius = radius - 5;

      if (!isCardinal) {
        canvas.drawLine(
          Offset(
            center.dx + innerRadius * math.cos(angle - math.pi / 2),
            center.dy + innerRadius * math.sin(angle - math.pi / 2),
          ),
          Offset(
            center.dx + outerRadius * math.cos(angle - math.pi / 2),
            center.dy + outerRadius * math.sin(angle - math.pi / 2),
          ),
          tickPaint,
        );
      }
    }

    // Small ticks
    final smallTickPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 10) {
      if (i % 30 != 0) {
        final angle = i * math.pi / 180;
        final innerRadius = radius - 10;
        final outerRadius = radius - 5;

        canvas.drawLine(
          Offset(
            center.dx + innerRadius * math.cos(angle - math.pi / 2),
            center.dy + innerRadius * math.sin(angle - math.pi / 2),
          ),
          Offset(
            center.dx + outerRadius * math.cos(angle - math.pi / 2),
            center.dy + outerRadius * math.sin(angle - math.pi / 2),
          ),
          smallTickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
