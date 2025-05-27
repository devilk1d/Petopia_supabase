import 'package:flutter/material.dart';

class CopyIconPainter extends CustomPainter {
  final Color color;

  CopyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double width = size.width;
    final double height = size.height;

    // Draw the front document
    final Path frontPath = Path();
    frontPath.moveTo(width * 0.3, height * 0.4);
    frontPath.lineTo(width * 0.3, height * 0.8);
    frontPath.lineTo(width * 0.8, height * 0.8);
    frontPath.lineTo(width * 0.8, height * 0.4);
    frontPath.close();

    // Draw the back document
    final Path backPath = Path();
    backPath.moveTo(width * 0.2, height * 0.2);
    backPath.lineTo(width * 0.2, height * 0.6);
    backPath.lineTo(width * 0.5, height * 0.6);

    // Draw the paths
    canvas.drawPath(frontPath, paint);
    canvas.drawPath(backPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}