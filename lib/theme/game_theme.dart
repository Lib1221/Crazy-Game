import 'package:flutter/material.dart';

class GameTheme {
  // Colors
  static const Color primaryColor = Color(0xFF6C63FF); // Vibrant purple
  static const Color secondaryColor = Color(0xFFFF6B6B); // Coral red
  static const Color accentColor = Color(0xFF4ECDC4); // Turquoise
  static const Color backgroundColor = Color(0xFF2D2D3A); // Dark background
  static const Color surfaceColor =
      Color(0xFF3D3D4A); // Slightly lighter background
  static const Color textColor = Colors.white;
  static const Color errorColor = Color(0xFFFF5252);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusExtraLarge = 24.0;

  // Shadows
  static List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 1.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 18,
    color: textColor,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 1.0,
  );

  // Input Decoration
  static InputDecoration getInputDecoration({
    required String label,
    required IconData prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
      prefixIcon: Icon(prefixIcon, color: primaryColor),
      errorText: errorText,
      errorStyle: const TextStyle(color: errorColor),
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        borderSide: const BorderSide(color: errorColor),
      ),
    );
  }

  // Button Style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: textColor,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    elevation: 4,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: textColor,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    elevation: 4,
  );
}
