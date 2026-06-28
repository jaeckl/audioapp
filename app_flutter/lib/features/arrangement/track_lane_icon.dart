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
    switch (track.iconKey) {
      case 'folder':
        return Icons.folder_outlined;
      case 'piano':
        return Icons.piano;
      case 'waveform':
        return Icons.graphic_eq;
      case 'microphone':
        return Icons.mic_external_on;
      case 'audio':
        return Icons.audiotrack;
      case 'album':
        return Icons.album_outlined;
      case 'speaker':
        return Icons.speaker;
    }
    if (track.isGroup) return Icons.folder_outlined;
    final stableIndex =
        track.id.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _laneIcons[stableIndex % _laneIcons.length];
  }
}
