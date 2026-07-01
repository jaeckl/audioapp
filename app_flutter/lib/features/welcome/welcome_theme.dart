import 'package:flutter/material.dart';

/// Shared visual tokens for the welcome / project-picker screen, matching the
/// dark chrome used across the device strip, library, and transport chrome
/// instead of stock Material widgets.
abstract final class WelcomeTheme {
  static const background = Color(0xFF0E0E14);
  static const panelBackground = Color(0xFF121218);
  static const panelBorder = Color(0x14FFFFFF);
  static const rowDivider = Color(0x0FFFFFFF);

  static const accent = Color(0xFF6C5CE7);
  static const accentSoft = Color(0x266C5CE7);
  static const error = Color(0xFFE85D4B);

  static const textPrimary = Color(0xFFE8E8F0);
  static const textMuted = Color(0xFF8A8A9A);

  static const double panelRadius = 14;
  static const double actionRadius = 14;
  static const double sectionGap = 24;

  static const sectionLabel = TextStyle(
    color: textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  );
}
