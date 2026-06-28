import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

/// Compact lane icon for a track row.
///
/// Font Awesome (via `font_awesome_flutter`) offers music glyphs such as guitar,
/// drum, and microphone, but this iteration uses built-in Material icons to avoid
/// a new dependency. Track name is exposed via tooltip and semantics.
class TrackLaneIcon {
  static const List<IconData> _laneIcons = [
    Icons.piano,
    Icons.graphic_eq,
    Icons.mic_external_on,
    Icons.audiotrack,
    Icons.album_outlined,
    Icons.speaker,
  ];

  static IconData iconForTrack(TrackSnapshot track, int index) {
    if (track.isGroup) {
      return Icons.folder_outlined;
    }
    if (track.devices.any((d) => d.type.contains('oscillator'))) {
      return Icons.graphic_eq;
    }
    return _laneIcons[index % _laneIcons.length];
  }
}
