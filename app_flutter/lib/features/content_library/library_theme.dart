import '../welcome/welcome_theme.dart';
import 'library_category.dart';
import 'package:flutter/material.dart';

/// Library chrome aligned with Project / Settings ([WelcomeTheme]).
abstract final class LibraryTheme {
  static const background = WelcomeTheme.background;
  static const panelBackground = WelcomeTheme.panelBackground;
  static const menuBackground = Color(0xFF101018);
  static const cardBackground = Color(0xFF16161E);
  static const border = WelcomeTheme.panelBorder;
  static const accent = WelcomeTheme.accent;
  static const accentMidi = Color(0xFF6EC9E8);
  static const accentAutomation = Color(0xFFB48CFF);
  static const accentCurve = Color(0xFFE879F9);
  static const accentPreset = Color(0xFF9A9AA8);
  static const accentWavetable = Color(0xFF3B82F6);
  static const accentAudio = Color(0xFFE8A54B);
  static const labelMuted = WelcomeTheme.textMuted;
  static const textPrimary = WelcomeTheme.textPrimary;

  static const double menuWidth = 96;
  static const double panelRadius = WelcomeTheme.panelRadius;

  /// Soft fill tinted from the active category / family accent (not purple).
  static Color softFill(Color accent, {double alpha = 0.14}) =>
      accent.withValues(alpha: alpha);

  static Color selectedFill(Color accent) => softFill(accent, alpha: 0.10);

  static Color accentFor(LibraryCategory category) => switch (category) {
        LibraryCategory.audioClips => accentAudio,
        LibraryCategory.midiClips => accentMidi,
        LibraryCategory.automationClips => accentAutomation,
        LibraryCategory.curves => accentCurve,
        LibraryCategory.devicePresets => accentPreset,
        LibraryCategory.wavetables => accentWavetable,
      };
}
