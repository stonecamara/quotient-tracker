import 'package:flutter/material.dart';

/// Palette claire, violette et pastel inspirée de la maquette Figma.
class AppColors {
  AppColors._();

  static const Color bgDark = Color(0xFFF9F8FF);
  static const Color bgDeep = Color(0xFFF3F0FF);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgCardLight = Color(0xFFEDE8FF);

  static const Color purple = Color(0xFF5B2DE8);
  static const Color purpleDark = Color(0xFF4920C8);
  static const Color purpleSoft = Color(0xFFF0EBFF);
  static const Color purpleGlow = Color(0x335B2DE8);

  // Alias conservés pour les widgets existants.
  static const Color cyan = purple;
  static const Color cyanDark = purpleDark;
  static const Color cyanGlow = purpleGlow;

  static const Color textPrimary = Color(0xFF262334);
  static const Color textSecondary = Color(0xFF716D7F);
  static const Color textMuted = Color(0xFFA19DAD);

  static const Color success = Color(0xFF48B58B);
  static const Color warning = Color(0xFFF19A63);
  static const Color danger = Color(0xFFE66B87);

  static const Color pastelBlue = Color(0xFFEAF7FF);
  static const Color pastelPink = Color(0xFFFFEFF5);
  static const Color pastelOrange = Color(0xFFFFF2E8);
  static const Color pastelYellow = Color(0xFFFFF9DF);

  static const Color bgCardCompleted = Color(0xFFEFFAF6);
  static const Color bgCardCompletedAlt = Color(0xFFF4F0FF);

  static Color cardColor(bool completed) {
    return completed ? bgCardCompleted : bgCard;
  }

  static Color quotientColor(int quotient) {
    if (quotient >= 80) return purple;
    if (quotient >= 60) return purple;
    if (quotient >= 40) return warning;
    if (quotient >= 20) return const Color(0xFFE99A45);
    return textMuted;
  }
}
