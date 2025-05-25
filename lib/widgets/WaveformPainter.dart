import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // First, draw the lighter background wave
    final path1 = Path()
      ..moveTo(0, size.height * 0.6)
      ..cubicTo(
        size.width * 0.25, size.height * 0.5, // control point 1
        size.width * 0.35, size.height * 0.7, // control point 2
        size.width * 0.5, size.height * 0.6, // end point
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.5,
        size.width * 0.75,
        size.height * 0.7,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint1 = Paint()
      ..color = const Color(0xFFEEEEEE) // very light grey
      ..style = PaintingStyle.fill;
    canvas.drawPath(path1, paint1);

    // Then draw the darker top wave on top of it
    final path2 = Path()
      ..moveTo(0, size.height * 0.65)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.55,
        size.width * 0.4,
        size.height * 0.75,
        size.width * 0.6,
        size.height * 0.65,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.55,
        size.width * 0.9,
        size.height * 0.75,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint2 = Paint()
      ..color = const Color(0xFFBBBBBB) // medium grey
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
