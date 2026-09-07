import 'package:flutter/material.dart';

/// 设计 token：浅色主题（首页 PRD v1.1 §10 定稿）
/// 白底 / 浅灰分隔 / 品牌橙 #fc4c02 / 白底文字强调深橙 #d64400。
abstract final class AppTheme {
  static const Color bg = Color(0xFFFFFFFF);
  static const Color bg2 = Color(0xFFF5F5F7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color card2 = Color(0xFFF2F2F5);
  static const Color line = Color(0x17171717); // rgba(17,17,21,.09)
  static const Color txt = Color(0xFF1B1B1F);
  static const Color txt2 = Color(0xFF5D5D67);
  static const Color txt3 = Color(0xFF9898A3);
  static const Color accent = Color(0xFFFC4C02);
  static const Color accentInk = Color(0xFFD64400);
  static const Color ok = Color(0xFF188A57);
  static const Color warn = Color(0xFFB98900);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        surface: bg,
      ),
      scaffoldBackgroundColor: bg,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: txt,
        displayColor: txt,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: txt,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
    );
  }
}
