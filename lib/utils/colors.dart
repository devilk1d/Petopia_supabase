import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primaryColor = Color(0xFFBF0055); // Main brand pink
  static const Color primaryLight = Color(0xFFE42C70); // Lighter shade for highlights
  static const Color primaryDark = Color(0xFF9A0044); // Darker shade for shadows

  // Background Colors
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8F8F8); // Very light grey for cards
  static const Color greyColor = Color(0xFFF6F6F6); // Light grey for inactive states

  // Text Colors
  static const Color textPrimary = Color(0xFF000000); // Black for primary text
  static const Color textSecondary = Color(0xFF535353); // Dark grey for secondary text
  static const Color textHint = Color(0xFFAEAEAE); // Light grey for hint text

  // Status Colors
  static const Color success = Color(0xFF108F6A); // Green for success/prices
  static const Color warning = Color(0xFFFFA000); // Orange for warnings
  static const Color error = Color(0xFFE02144); // Red for errors
  static const Color info = Color(0xFF5FA3F1); // Blue for information

  // Banner Colors (with a more consistent palette)
  static const Color purpleBanner = Color(0xFFB84ACB);
  static const Color orangeBanner = Color(0xFFFFA000);
  static const Color greenBanner = Color(0xFF20C997);
  static const Color redBanner = Color(0xFFE02144);

  // Category Colors (harmonized with main color scheme)
  static const Color makananColor = Color(0xFFBF0055); // Primary color for Makanan
  static const Color vitaminColor = Color(0xFF9340B8); // Purple for Vitamin
  static const Color mainanColor = Color(0xFF5BD090); // Green for Mainan
  static const Color aksesorisColor = Color(0xFF5F5BD0); // Blue for Aksesoris
  static const Color kandangColor = Color(0xFFECA42F); // Orange/Yellow for Kandang
  static const Color groomingColor = Color(0xFF5FA3F1); // Blue for Grooming

  // Shadow & Overlay Colors
  static Color shadowColor = Colors.black.withOpacity(0.1);
  static Color overlayColor = Colors.black.withOpacity(0.5);

  // Helper Method to create transparent version of colors
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Helper Method to create a gradient from a base color
  static LinearGradient gradient(Color color, {bool vertical = true}) {
    final Color darkerColor = darken(color, 0.15);

    return LinearGradient(
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: [color, darkerColor],
    );
  }

  // Helper Method to darken a color
  static Color darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  // Helper Method to lighten a color
  static Color lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}