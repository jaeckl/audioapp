import 'package:flutter/material.dart';

import '../welcome/welcome_theme.dart';

/// Arrangement chrome — Welcome / Project hub panel language.
///
/// Clip fills, loop cyan, and playhead stay on their own themes
/// ([ArrangementClipTheme], loop/playhead markers).
abstract final class ArrangementTheme {
  static const background = WelcomeTheme.background;
  static const panelBackground = WelcomeTheme.panelBackground;
  static const menuBackground = Color(0xFF101018);
  static const cardBackground = Color(0xFF16161E);
  static const surface = WelcomeTheme.panelBackground;
  static const rulerBackground = WelcomeTheme.panelBackground;
  static const border = WelcomeTheme.panelBorder;
  static const divider = WelcomeTheme.rowDivider;
  static const textPrimary = WelcomeTheme.textPrimary;
  static const textMuted = WelcomeTheme.textMuted;

  /// Selected track header fill (neutral — not brand purple).
  static const headerSelected = Color(0xFF1C1C26);

  /// Selected lane wash over the grid.
  static final laneSelected = const Color(0xFF1C1C26).withValues(alpha: 0.65);

  static const mixButtonIdle = cardBackground;
  static const rulerIdlePill = Color(0xFF1C1C26);

  /// Master strip keeps warm identity, tuned to Welcome dark stack.
  static const masterHeader = Color(0xFF1A1814);
  static final masterLaneWash = const Color(0xFF201810).withValues(alpha: 0.72);
  static final masterBorder = Colors.amber.withValues(alpha: 0.35);
  static final masterIcon = Colors.amber.shade200;
  static final masterLabel = Colors.amber.shade100;

  static const dragFeedbackFill = cardBackground;
  static const dragFeedbackBorder = border;
}
