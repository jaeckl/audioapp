import 'package:flutter/material.dart';

/// Arrangement timeline clip colors.
abstract final class ArrangementClipTheme {
  static const midiClipBackground = Color(0xFF3A4A6B);
  static const sampleClipBackground = Color(0xFF2E4A3A);

  static const midiClipBorder = Color(0x40FFFFFF);
  static const sampleClipBorder = Color(0xFF5A9E78);

  static const highlightBorder = Color(0xFF8EB4FF);
  static const highlightShadow = Color(0xFF8EB4FF);

  static const midiNoteFill = Color(0xB0C8D8F5);
  static const sampleWaveform = Color(0xFF9AD4B3);

  static const placeholderLabel = Color(0xB3FFFFFF);

  static const automationClipBackground = Color(0xFF4A3868);
  static const automationClipBorder = Color(0xFFB48CFF);
  static const automationCurve = Color(0xFFE0CCFF);
  static const automationCurveRepeat = Color(0x99C9B0E8);

  /// Subtle dim overlay on looped repeat regions (after the first cycle).
  static final loopRepeatOverlay = Color(0xFF000000).withValues(alpha: 0.2);

  static const midiNoteFillRepeat = Color(0x78A8C0E0);
  static const sampleWaveformRepeat = Color(0x809AD4B3);

  static const freezeClipBackground = Color(0xFF3A3A52);
  static const freezeClipBorder = Color(0xFF9AA8FF);
  static const freezeWaveform = Color(0xFFB8C4FF);

  /// Darker fill behind condensed clip content (notes, waveform).
  static Color contentBackground(Color clipBackground) {
    return Color.lerp(clipBackground, Colors.black, 0.38)!;
  }

  /// Clip body tinted from track highlight (readable on dark timeline).
  static Color clipBackgroundFromAccent(Color accent) {
    return Color.lerp(const Color(0xFF141418), accent, 0.45)!;
  }

  static Color clipBorderFromAccent(Color accent) {
    return accent.withValues(alpha: 0.55);
  }

  static Color clipHighlightFromAccent(Color accent) {
    return Color.lerp(accent, Colors.white, 0.35)!;
  }

  /// Condensed note / waveform / curve fill from track accent.
  static Color clipContentFillFromAccent(Color accent) {
    return Color.lerp(Colors.white, accent, 0.28)!;
  }

  static Color clipContentFillRepeatFromAccent(Color accent) {
    return clipContentFillFromAccent(accent).withValues(alpha: 0.48);
  }

  /// Clip-edge rails use the clip type's content color so the affordance is
  /// discoverable without reading as a separate button.
  static const Color resizeHandleMidiIdleColor = Color(0xFF8EB4FF);
  static const Color resizeHandleSampleIdleColor = Color(0xFF9AD4B3);
  static const Color resizeHandleAutomationIdleColor = Color(0xFFB48CFF);
  static const Color resizeHandleActiveColor = Color(0xFFFFFFFF);
}
