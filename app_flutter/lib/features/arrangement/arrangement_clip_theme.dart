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

  /// Darker fill behind condensed clip content (notes, waveform).
  static Color contentBackground(Color clipBackground) {
    return Color.lerp(clipBackground, Colors.black, 0.38)!;
  }

  /// Resize handle idle colors matching each clip's color scheme.
  /// Bright enough to read against any background.
  static const Color resizeHandleMidiIdleColor = Color(0xFF8EB4FF);
  static const Color resizeHandleSampleIdleColor = Color(0xFF9AD4B3);
  static const Color resizeHandleAutomationIdleColor = Color(0xFFB48CFF);
  static const Color resizeHandleActiveColor = Color(0xFFFFFFFF);
}
