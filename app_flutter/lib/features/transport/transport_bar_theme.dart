import 'package:flutter/material.dart';

/// Visual tokens for the shell transport header.
abstract final class TransportBarTheme {
  static const background = Color(0xFF121218);
  static const chipFill = Color(0xFF181820);
  static const panelBorder = Color(0x14FFFFFF);
  static const chipBorder = Color(0x1FFFFFFF);
  static const accentLoop = Color(0xFFE8A54B);
  static const accentPlay = Color(0xFF6EC6FF);
  static const accentRecord = Color(0xFFE85B5B);
  static const textPrimary = Color(0xFFE8E8EE);
  static const textSecondary = Color(0xFF9A9AA8);
  static const textMuted = Color(0xFF5C5C6A);

  /// Popup menus anchored from the transport bar (grid snap, etc.).
  static const menuBackground = chipFill;
  static const menuPillIdle = Color(0xFF22222C);
  static const menuPillActiveFill = Color(0xFF3A3A50);
  static const menuPillActiveText = textPrimary;

  static const double rowHeight = 56;
  static const double barPaddingV = 2;
  static const double barPaddingH = 8;
  static const double cardGap = 4;
  static const double panelRadius = 14;
  static const double cardRadius = 10;
  static const double cardInnerPaddingV = 2;
  static const double cardInnerPaddingH = 4;
  static const double statusIconSize = 16;
  static const double statusIconHit = 28;
  static const double bpmBoxWidth = 56;
}
