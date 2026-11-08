import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary brand palette
  static const Color background = Color(0xFF0F1113);
  static const Color surface = Color(0xFF181B1E);
  static const Color surfaceDark = Color(0xFF14171A);
  static const Color border = Color(0xFF262A2E);
  static const Color borderLight = Color(0xFF2E3338);
  static const Color borderSubtle = Color(0xFF3A4046);

  // Typography
  static const Color text = Color(0xFFF2F4F1);
  static const Color textMuted = Color(0xFF9BA3A8);
  static const Color textOnAccent = Color(0xFF0F1500);

  // Accents & status
  static const Color accentLime = Color(0xFFD4FF3A);
  static const Color accentLimeMuted = Color(0x26D4FF3A); // 15% opacity
  static const Color warning = Color(0xFFFF9466);
  static const Color warningBg = Color(0xFF2A1A12);
  static const Color success = Color(0xFF3AD48A);

  // Glass / overlay colors
  static const Color overlayDark = Color(0xD90F1113); // 85%
  static const Color overlaySurface = Color(0xEB181B1E); // 92%
}

