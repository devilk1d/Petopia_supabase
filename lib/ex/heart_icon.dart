import 'package:flutter/material.dart';

class HeartIconPainter extends CustomPainter {
  const HeartIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFE02145)
      ..style = PaintingStyle.fill;

    final Path path = Path();

    // Scale the heart path to fit the size
    final double width = size.width;
    final double height = size.height;

    // Heart shape path
    path.moveTo(width * 0.5, height * 0.85);
    path.cubicTo(
        width * 0.4, height * 0.7,
        width * 0.1, height * 0.5,
        width * 0.25, height * 0.25
    );
    path.cubicTo(
        width * 0.35, height * 0.1,
        width * 0.5, height * 0.2,
        width * 0.5, height * 0.3
    );
    path.cubicTo(
        width * 0.5, height * 0.2,
        width * 0.65, height * 0.1,
        width * 0.75, height * 0.25
    );
    path.cubicTo(
        width * 0.9, height * 0.5,
        width * 0.6, height * 0.7,
        width * 0.5, height * 0.85
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}