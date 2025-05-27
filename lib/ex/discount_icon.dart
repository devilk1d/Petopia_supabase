import 'package:flutter/material.dart';

class DiscountIconPainter extends CustomPainter {
  final Color color;

  DiscountIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();

    // This is a simplified version of the discount icon from the design
    // Drawing the main shape of the discount tag
    final double width = size.width;
    final double height = size.height;

    // Main rectangle
    path.moveTo(width * 0.1, height * 0.2);
    path.lineTo(width * 0.9, height * 0.2);
    path.lineTo(width * 0.9, height * 0.8);
    path.lineTo(width * 0.1, height * 0.8);
    path.close();

    // Cut out for the tag hole
    final double holeSize = width * 0.1;
    path.addOval(Rect.fromCircle(
      center: Offset(width * 0.2, height * 0.3),
      radius: holeSize,
    ));

    // Diagonal line for the discount
    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.02;

    canvas.drawLine(
      Offset(width * 0.3, height * 0.3),
      Offset(width * 0.7, height * 0.7),
      linePaint,
    );

    // Small circles at each end of the diagonal line
    final double dotSize = width * 0.05;
    canvas.drawCircle(
      Offset(width * 0.3, height * 0.3),
      dotSize,
      paint,
    );

    canvas.drawCircle(
      Offset(width * 0.7, height * 0.7),
      dotSize,
      paint,
    );

    // Draw the main path
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}