import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final String iconPath;
  final String name;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const CategoryItem({
    Key? key,
    required this.iconPath,
    required this.name,
    required this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create gradient colors for a more modern look
    final Color darkShade = HSLColor.fromColor(backgroundColor)
        .withLightness(
        (HSLColor.fromColor(backgroundColor).lightness - 0.15).clamp(0.0, 1.0))
        .toColor();

    final Color lightShade = HSLColor.fromColor(backgroundColor)
        .withLightness(
        (HSLColor.fromColor(backgroundColor).lightness + 0.05).clamp(0.0, 1.0))
        .toColor();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Container with shadow for depth
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              // More elegant gradient direction
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  lightShade,
                  backgroundColor,
                  darkShade,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              // Add subtle animation to icon
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Image.asset(
                  iconPath,
                  width: 36,
                  height: 36,
                  color: Colors.white,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if image not found
                    return const Icon(
                      Icons.category,
                      size: 36,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Category name with improved typography
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}