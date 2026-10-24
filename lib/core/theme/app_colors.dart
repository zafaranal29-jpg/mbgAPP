import 'package:flutter/material.dart';

/// Palet warna MBG (mengikuti referensi desain biru e-learning).
/// Hijau = sukses klaim, Merah = gagal (sesuai blueprint).
class AppColors {
  AppColors._();

  static const Color primaryDark = Color(0xFF0A2A9C);
  static const Color primary = Color(0xFF1655D8);
  static const Color accent = Color(0xFF1DA8E6);
  static const Color background = Color(0xFFF3F6FC);
  static const Color textDark = Color(0xFF1B2559);
  static const Color textGrey = Color(0xFF8A94A6);

  static const Color success = Color(0xFF2EBD6B);
  static const Color successDark = Color(0xFF168A4A);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFF5A524);
  static const Color star = Color(0xFFFFB400);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A2A9C), Color(0xFF1655D8), Color(0xFF1DA8E6)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF1655D8), Color(0xFF1DA8E6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF168A4A), Color(0xFF2EBD6B), Color(0xFF52D68A)],
  );
}

extension ColorOpacityX on Color {
  /// Pengganti withOpacity (kompatibel semua versi Flutter).
  Color op(double opacity) =>
      withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}
