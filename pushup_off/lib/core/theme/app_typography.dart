import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  // Barlow Condensed - Big Numbers, Hero Headings, Uppercase Buttons (w700)
  static TextStyle heroNumber({Color color = AppColors.text, double fontSize = 72}) {
    return GoogleFonts.barlowCondensed(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -1.0,
      height: 0.95,
    );
  }

  static TextStyle displayLarge({Color color = AppColors.text, double? fontSize}) {
    return GoogleFonts.barlowCondensed(
      fontSize: fontSize ?? 36,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.5,
      height: 1.1,
    );
  }

  static TextStyle displayMedium({Color color = AppColors.text, double? fontSize}) {
    return GoogleFonts.barlowCondensed(
      fontSize: fontSize ?? 28,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.3,
      height: 1.15,
    );
  }

  static TextStyle displaySmall({Color color = AppColors.text, double? fontSize}) {
    return GoogleFonts.barlowCondensed(
      fontSize: fontSize ?? 22,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.0,
      height: 1.2,
    );
  }

  static TextStyle buttonUppercase({Color color = AppColors.textOnAccent, double fontSize = 18}) {
    return GoogleFonts.barlowCondensed(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: color,
    );
  }

  // Barlow - Regular Body & UI Text
  static TextStyle titleLarge({Color color = AppColors.text, double? fontSize}) {
    return GoogleFonts.barlow(
      fontSize: fontSize ?? 20,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle titleMedium({Color color = AppColors.text, double? fontSize}) {
    return GoogleFonts.barlow(
      fontSize: fontSize ?? 16,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle bodyLarge({Color color = AppColors.text, double? fontSize}) {
    return GoogleFonts.barlow(
      fontSize: fontSize ?? 16,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle bodyMedium({Color color = AppColors.text, double? fontSize}) {
    return GoogleFonts.barlow(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle bodySmall({Color color = AppColors.textMuted, double? fontSize}) {
    return GoogleFonts.barlow(
      fontSize: fontSize ?? 12,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle caption({Color color = AppColors.textMuted, double? fontSize}) {
    return GoogleFonts.barlow(
      fontSize: fontSize ?? 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: color,
    );
  }
}

