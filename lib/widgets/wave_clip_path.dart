import 'package:flutter/material.dart';

/// Clips the container into a single smooth dome curve at the top
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top left corner at y=60 to match the attachment
    path.moveTo(0, 60);

    // Single dome curve (quadratic Bezier) with -40 control point for a smooth dome
    path.quadraticBezierTo(
      size.width / 2, // control point x: center width
      -40, // control point y: creates the dome peak above the container
      size.width, // end point x: right edge
      60, // end point y: 60 px down to match left side
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
