

import 'package:flutter/material.dart';

class VideoTrianglePainter extends CustomPainter {
  final Color color;
  bool right = true;

  VideoTrianglePainter(this.color, this.right);

  @override
  void paint(Canvas canvas, Size size) {
    if (right) {
      final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw a right triangle (play button shape)
    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.lineTo(0, size.height * 1);
    path.lineTo(size.width * 0.8, size.height * 1);
    path.close();

    canvas.drawPath(path, paint);
    } else { 
      final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw a right triangle (play button shape)
    final path = Path();
    path.moveTo(size.width, size.height * 0.2);
    path.lineTo(0, size.height * 1);
    path.lineTo(size.width, size.height * 1);
    path.close();

    canvas.drawPath(path, paint);
    }
    
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}