import 'package:flutter/material.dart';

/// Clips the container into a single smooth dome curve at the top
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top left corner
    path.moveTo(0, 40);

    // Single dome curve (quadratic Bezier)
    path.quadraticBezierTo(
      size.width / 2, // control point x: center width
      0, // control point y: top edge (dome peak)
      size.width, // end point x: right edge
      40, // end point y: 40 px down
    );

    // Complete rectangle
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
