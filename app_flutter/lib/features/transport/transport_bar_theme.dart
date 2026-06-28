import 'package:flutter/material.dart';

/// Visual tokens for the shell transport header.
abstract final class TransportBarTheme {
  static const background = Color(0xFF0E0E14);
  static const chipFill = Color(0xFF16161E);
  static const chipBorder = Color(0x24FFFFFF);
  static const accentLoop = Color(0xFFE8A54B);
  static const accentPlay = Color(0xFF6EC6FF);
  static const accentRecord = Color(0xFFE85B5B);
  static const textPrimary = Color(0xFFE8E8EE);
  static const textSecondary = Color(0xFF9A9AA8);
  static const textMuted = Color(0xFF5C5C6A);

  static const double rowHeight = 56;
  static const double barPaddingV = 2;
  static const double barPaddingH = 8;
  static const double cardGap = 4;
  static const double cardInnerPaddingV = 2;
  static const double cardInnerPaddingH = 4;
  static const double statusIconSize = 16;
  static const double statusIconHit = 28;
  static const double bpmBoxWidth = 56;
}
