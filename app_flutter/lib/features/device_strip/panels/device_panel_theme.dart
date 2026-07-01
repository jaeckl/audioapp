import 'package:flutter/material.dart';

/// Shared visual tokens for device panel sections (filters, envelopes, etc.).
abstract final class DevicePanelTheme {
  static const previewBackground = Color(0xFF0E0E14);
  static const sectionBackground = Color(0xFF121218);
  static const sectionBorder = Color(0x14FFFFFF);
  static const sectionRadius = 6.0;

  static const previewHeroHeight = 92.0;
  static const previewStripHeight = 28.0;
  static const modeRowHeight = 30.0;
  static const sectionGap = 8.0;
  static const knobRowGap = 10.0;

  static const sectionLabel = TextStyle(
    color: Colors.white30,
    fontSize: 8,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static BoxDecoration previewDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: previewBackground,
      borderRadius: BorderRadius.circular(sectionRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  static BoxDecoration sectionDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: sectionBackground,
      borderRadius: BorderRadius.circular(sectionRadius),
      border: Border.all(
        color: borderColor ?? sectionBorder,
      ),
    );
  }
}
