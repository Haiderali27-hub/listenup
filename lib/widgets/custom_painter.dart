import 'package:flutter/material.dart';

class CurvedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..shader = LinearGradient(
        colors: [
          Colors.black.withOpacity(0.4),
          Colors.black.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();

    path.moveTo(0, 40);
    path.quadraticBezierTo(
      size.width / 2,
      0,
      size.width,
      40,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
