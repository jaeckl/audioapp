import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

/// Stable per-track highlight colors (mixer accents, header washes).
abstract final class TrackLaneColor {
  static const List<Color> _palette = [
    Color(0xFF5B8DEF), // blue
    Color(0xFF6BCB77), // green
    Color(0xFFCF6A8E), // rose
    Color(0xFF7B6CFF), // violet
    Color(0xFF4DB6AC), // teal
    Color(0xFFFF8A65), // coral
    Color(0xFF64B5F6), // light blue
    Color(0xFFD4E157), // lime
  ];

  static const Color master = Color(0xFFE0C070);

  static Color colorForTrack(TrackSnapshot track, int index) {
    if (track.isGroup || track.iconKey == 'folder') {
      return const Color(0xFFB0A090);
    }
    final stable = track.id.codeUnits.fold<int>(0, (sum, u) => sum + u);
    return _palette[(stable + index) % _palette.length];
  }

  /// Dark-surface wash for arrangement headers / mixer cards.
  static Color headerWash(Color accent, {required bool selected}) {
    return accent.withValues(alpha: selected ? 0.32 : 0.14);
  }
}
