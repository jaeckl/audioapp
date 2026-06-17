import 'package:flutter/material.dart';

import 'library_category.dart';

abstract final class LibraryTheme {
  static const panelBackground = Color(0xFF101018);
  static const menuBackground = Color(0xFF16161E);
  static const cardBackground = Color(0xFF1C1C26);
  static const border = Color(0xFF3A3A48);
  static const accent = Color(0xFFE8A54B);
  static const accentMidi = Color(0xFF6EC9E8);
  static const accentAutomation = Color(0xFFB48CFF);
  static const accentPreset = Color(0xFF9A9AA8);
  static const labelMuted = Color(0xFF8A8A9A);

  static const double menuWidth = 92;

  static Color accentFor(LibraryCategory category) => switch (category) {
        LibraryCategory.audioClips => accent,
        LibraryCategory.midiClips => accentMidi,
        LibraryCategory.automationClips => accentAutomation,
        LibraryCategory.devicePresets => accentPreset,
      };
}
