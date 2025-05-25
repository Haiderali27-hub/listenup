import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.6,
        size.width * 0.4, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.85,
        size.width * 0.6, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.55,
        size.width * 1.0, size.height * 0.65);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw a second wave with lighter opacity
    final paint2 = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path2 = Path();

    path2.moveTo(0, size.height * 0.85);
    path2.quadraticBezierTo(size.width * 0.15, size.height * 0.65,
        size.width * 0.35, size.height * 0.8);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.9,
        size.width * 0.65, size.height * 0.75);
    path2.quadraticBezierTo(size.width * 0.85, size.height * 0.6,
        size.width * 1.0, size.height * 0.7);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
