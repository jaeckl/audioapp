import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'library_theme.dart';

part 'library_preset_preview_bar_preset_preview_bar_state.dart';
part 'library_preset_preview_bar_preset_timeline_painter.dart';
part 'library_preset_preview_bar_clip_timeline_span.dart';
part 'library_preset_preview_bar_clip_content_kind.dart';

/// Mini arrangement viewport shown when a preset is selected.
///
/// Mirrors the selected track end-to-end (one row, all clip kinds on a single
/// shared timeline). The visible 8-bar window slides across the full track so
/// long tracks stay explorable — the user just scrubs (taps/drags) to pan, or
/// taps a clip to jump there.
class PresetPreviewBar extends StatefulWidget {
  const PresetPreviewBar({
    super.key,
    required this.snapshot,
    required this.selectedTrackId,
    required this.displayPlayhead,
    required this.onClipTap,
  });

  final ProjectSnapshot snapshot;
  final String? selectedTrackId;
  final bool displayPlayhead;
  final void Function(ClipTimelineSpan clip) onClipTap;

  @override
  State<PresetPreviewBar> createState() => _PresetPreviewBarState();
}

/// Paints the preset preview bar timeline background + clip spans.
/// Builds [ClipTimelineSpan] list for a track by combining MIDI/sample/
/// automation clips into a flat list sorted by startBeat.
List<ClipTimelineSpan> buildClipTimeline(TrackSnapshot track) {
  final spans = <ClipTimelineSpan>[];
  for (final clip in track.midiClips) {
    spans.add(ClipTimelineSpan(
      name: '[MIDI] ${track.name}',
      kind: ClipContentKind.midi,
      startBeat: clip.startBeat,
      lengthBeats: clip.lengthBeats,
    ));
  }
  for (final clip in track.sampleClips) {
    spans.add(ClipTimelineSpan(
      name: clip.sampleId.isNotEmpty ? clip.sampleId : '[Sample]',
      kind: ClipContentKind.sample,
      startBeat: clip.startBeat,
      lengthBeats: clip.lengthBeats,
    ));
  }
  for (final clip in track.automationClips) {
    spans.add(ClipTimelineSpan(
      name: '${clip.deviceId} ${clip.paramId}',
      kind: ClipContentKind.automation,
      startBeat: clip.startBeat,
      lengthBeats: clip.lengthBeats,
    ));
  }
  spans.sort((a, b) => a.startBeat.compareTo(b.startBeat));
  return spans;
}

/// A single visible span of a clip on the preset preview timeline.
///
/// Renders the item's name, a colored accent matching its kind, and the clip's
/// actual waveform/summary preview when available.
/// The kind of content a clip timeline span represents.
