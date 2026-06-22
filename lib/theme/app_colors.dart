import "package:flutter/material.dart";

class AppColors {
  static const bg = Color(0xFFF7F2EF);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF0F0F10);
  static const muted = Color(0xFF7B7575);
  static const primary = Color(0xFFA41E22);
  static const primaryDark = Color(0xFF7A1417);
  static const accent = Color(0xFFFAD3CF);
  static const accentDeep = Color(0xFFE89B95);
  static const ring = Color(0xFFE8DDD8);

  static const buttonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFB8262B), Color(0xFFA41E22), Color(0xFF7A1417)],
    stops: [0.0, 0.5, 1.0],
  );
}
