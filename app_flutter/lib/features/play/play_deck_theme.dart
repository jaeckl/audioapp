import 'package:flutter/material.dart';

export 'play_deck_layout.dart'
    show
        PlaySurfaceMode,
        PlayContextView,
        ArpMode,
        ArpModeLabel,
        ChordQuality,
        ChordQualityLabel;

/// Flat palette for the play deck — minimal chrome, no key borders.
abstract final class PlayDeckTheme {
  static const deckBackground = Color(0xFF1C1C20);
  static const railBackground = Color(0xFF1C1C20);
  static const gapColor = Color(0xFF121216);
  static const panelBackground = Color(0xFF15151A);

  static const padIdle = Color(0xFF2E2E34);
  static const padActive = Color(0xFFE87B8A);

  static const keyIdle = Color(0xFF2E2E34);
  static const keyWhite = Color(0xFFD8D8DE);
  static const keyBlack = Color(0xFF1A1A1E);
  static const keyActive = Color(0xFFE87B8A);
  static const keyRoot = Color(0xFFC9A04A);

  static const railActive = Colors.white;
  static const railInactive = Color(0xFF6A6A72);
  static const railLabel = Color(0xFF8A8A92);

  static const optionIdle = Color(0xFF25252C);
  static const optionActive = Color(0xFFE87B8A);
  static const optionLabel = Color(0xFFDEDEDE);

  static const cellGap = 2.0;
  static const railWidth = 60.0;
}
