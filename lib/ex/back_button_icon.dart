import 'package:flutter/material.dart';

class BackButtonIconPainter extends CustomPainter {
  const BackButtonIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final Path path = Path();

    // Drawing the back arrow
    path.moveTo(size.width * 0.7, size.width * 0.2); // Top-right point
    path.lineTo(size.width * 0.3, size.width * 0.5); // Middle-left point
    path.lineTo(size.width * 0.7, size.width * 0.8); // Bottom-right point

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}