import 'package:flutter/material.dart';

/// Shared chrome for device chain cards.
abstract final class DeviceStripTheme {
  static const stripBackground = Color(0xFF121218);
  static const cardBackground = Color(0xFF1A1A24);
  static const cardHeader = Color(0xFF22222E);
  static const toolRailBackground = Color(0xFF16161E);
  static const cardBorder = Color(0xFF4A4A5C);
  static const cardBorderHighlight = Color(0xFF6A6A7C);
  static const cardShadow = Color(0x99000000);

  static const samplerAccent = Color(0xFFE8A54B);
  static const oscillatorAccent = Color(0xFF6EC9E8);
  static const genericAccent = Color(0xFF9A9AA8);

  static const double toolRailRadius = 10;
  static const double cardRadius = 2;
  static const double cardBorderWidth = 1.5;
  static const double headerHeight = 22;
  static const double accentStripeWidth = 4;

  /// Header + divider inside [DeviceStripCard].
  static const double cardChromeHeight = headerHeight + 1;

  static const double slotVerticalPadding = 4;

  static const double collapsedChainTopPadding = 0;
  static const double collapsedChainBottomPadding = 4;
  static const double collapsedSlotTopPadding = 0;

  static Color accentForDeviceType(String type) => switch (type) {
        'simple_sampler' => samplerAccent,
        'simple_oscillator' => oscillatorAccent,
        _ => genericAccent,
      };

  static String labelForDeviceType(String type) => switch (type) {
        'simple_sampler' => 'Sampler',
        'simple_oscillator' => 'Oscillator',
        _ => type,
      };
}
