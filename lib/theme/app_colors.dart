import 'package:flutter/material.dart';

/// Palette dark blue / cyan — style illustration flat.
class AppColors {
  AppColors._();

  // ── Fond ──
  static const Color bgDark = Color(0xFF0A1638);
  static const Color bgDeep = Color(0xFF0E1F4F);
  static const Color bgCard = Color(0xFF162557);
  static const Color bgCardLight = Color(0xFF1E3068);

  // ── Accent ──
  static const Color cyan = Color(0xFF00D4FF);
  static const Color cyanDark = Color(0xFF00A8CC);
  static const Color cyanGlow = Color(0x4400D4FF);

  // ── Texte ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8FA3CC);
  static const Color textMuted = Color(0xFF5A6E94);

  // ── États ──
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFFF5252);

  // ── Couleurs de fond (sans dégradé) ──
  static const Color bgCardCompleted = Color(0xFF0D3D2E);
  static const Color bgCardCompletedAlt = Color(0xFF0A2E44);

  static Color cardColor(bool completed) {
    return completed ? bgCardCompleted : bgCard;
  }

  /// Couleur du quotient selon le pourcentage.
  static Color quotientColor(int quotient) {
    if (quotient >= 80) return success;
    if (quotient >= 60) return cyan;
    if (quotient >= 40) return warning;
    if (quotient >= 20) return const Color(0xFFFF9800);
    return textMuted;
  }
}
