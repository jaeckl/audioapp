import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../arrangement/arrangement_theme.dart';

/// Shared mixer strip chrome / sizing.
abstract final class MixerTheme {
  static const double panelHeight = 360;
  static const double channelWidth = 120;
  static const double channelGap = 8;
  static const double channelRadius = 8;
  static const EdgeInsets channelPadding = EdgeInsets.fromLTRB(8, 8, 8, 6);

  static const double nameFontSize = 13;
  static const double readoutFontSize = 11;
  static const double menuFontSize = 12;
  static const double headerIconSize = 18;

  static const double meterWidth = 22;
  static const double meterBarGap = 3;

  /// Vertical gain fader.
  static const double faderHitWidth = 32;
  static const double faderWellWidth = 12;
  static const double faderRailWidth = 3;
  static const double faderCapWidth = 20;
  static const double faderCapHeight = 14;

  /// Horizontal pan fader.
  static const double panRowHeight = 40;
  static const double panWellHeight = 14;
  static const double panRailHeight = 3;
  static const double panCapWidth = 16;
  static const double panCapHeight = 20;

  static const double mixButtonHeight = 32;
  static const double outputRowHeight = 36;

  static const Color panelBackground = Color(0xFF121218);
  static const Color trackFill = Color(0xFF191920);
  static const Color trackFillSelected = Color(0xFF23232D);
  static const Color masterFill = Color(0xFF28241A);
  static const Color masterFillSelected = Color(0xFF2E2A1E);
  static const Color accent = Color(0xFFE8A54B);
  static const Color accentIdle = Color(0xFF777787);
  static const Color menuBackground = Color(0xFF1E1E28);
  static const Color trough = Color(0xFF0C0C12);
  /// Shared flat surface for mix group + output chip.
  static const Color chromeSurface = Color(0xFF16161E);
  static const Color wellFill = Color(0xFF0A0A10);
  static const Color wellRim = Color(0x14FFFFFF);
  static const Color capFill = Color(0xFFEDE6D8);
  static const Color capEdge = Color(0x66FFFFFF);

  static Color get masterBorder => ArrangementTheme.masterBorder;
  static Color get masterIcon => ArrangementTheme.masterIcon;
  static Color get textPrimary => ArrangementTheme.textPrimary;
  static Color get textMuted => ArrangementTheme.textMuted;

  static String gainLabel(double gain) {
    final g = gain.clamp(0.0, 1.0);
    if (g <= 0.0001) return '-∞ dB';
    final db = 20 * math.log(g) / math.ln10;
    final rounded = db.round();
    if (rounded >= 0) return '+$rounded dB';
    return '$rounded dB';
  }
}
