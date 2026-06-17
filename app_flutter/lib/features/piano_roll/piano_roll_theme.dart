import 'package:flutter/material.dart';

import '../play/play_deck_theme.dart';

/// Piano roll colors — aliases [PlayDeckTheme] so the editor matches Play mode.
abstract final class PianoRollTheme {
  static const background = PlayDeckTheme.deckBackground;
  static const surface = PlayDeckTheme.panelBackground;
  static const rulerBackground = PlayDeckTheme.stripBackground;
  static const keyColumnBackground = PlayDeckTheme.railBackground;

  static const whiteKey = PlayDeckTheme.keyWhite;
  static const blackKey = PlayDeckTheme.keyBlack;
  /// Key-column row stripes — ivory whites for white keys only (not the note canvas).
  static const whiteKeyRow = Color(0xFFF5F0E6);
  static const blackKeyRow = Color(0xFF35353F);
  static const whiteKeyLabel = Color(0xFF5C5348);
  static const cKeyAccent = PlayDeckTheme.keyRoot;

  static const gridBar = Color(0x22FFFFFF);
  static const gridBeat = Color(0x10FFFFFF);
  static const clipRegionFill = Color(0x08FFFFFF);
  static const clipBoundary = PlayDeckTheme.optionActive;
  static const double clipEndLineWidth = 2;
  static const outsideClipDim = Color(0x44000000);

  static const noteFill = PlayDeckTheme.padIdle;
  static const noteSelected = PlayDeckTheme.padActive;
  static const noteBorder = Color(0x30FFFFFF);
  static const noteBorderSelected = Colors.white;

  static const dockBackground = PlayDeckTheme.stripBackground;
  static const dockActive = PlayDeckTheme.optionIdle;
  static const dockIcon = PlayDeckTheme.railInactive;
  static const dockIconActive = PlayDeckTheme.railActive;
  static const labelMuted = PlayDeckTheme.railLabel;
  static const label = PlayDeckTheme.optionLabel;
  static const accent = PlayDeckTheme.optionActive;
  static const saveOk = Color(0xFF6BCB8B);
  static const saveError = PlayDeckTheme.padActive;
}
