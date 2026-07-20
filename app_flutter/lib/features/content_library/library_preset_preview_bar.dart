import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'library_theme.dart';

part 'library_preset_preview_bar_preset_preview_bar_state.dart';
part 'library_preset_preview_bar_preset_timeline_painter.dart';
part 'library_preset_preview_bar_clip_timeline_span.dart';

/// Mini arrangement minimap for preset preview: MIDI notes + scrub + loop/stop.
class PresetPreviewBar extends StatefulWidget {
  const PresetPreviewBar({
    super.key,
    required this.snapshot,
    required this.selectedTrackId,
    required this.playheadBeat,
    required this.onScrub,
    required this.onClipTap,
    required this.loopEnabled,
    required this.onLoopToggled,
    required this.onStop,
    this.previewPlaying = false,
    this.accent = LibraryTheme.accent,
  });

  final ProjectSnapshot snapshot;
  final String? selectedTrackId;
  final double playheadBeat;
  final ValueChanged<double> onScrub;
  final void Function(PresetPreviewClipSpan clip) onClipTap;
  final bool loopEnabled;
  final ValueChanged<bool> onLoopToggled;
  final VoidCallback onStop;
  final bool previewPlaying;
  final Color accent;

  @override
  State<PresetPreviewBar> createState() => _PresetPreviewBarState();
}

List<PresetPreviewClipSpan> buildClipTimeline(TrackSnapshot track) {
  final spans = <PresetPreviewClipSpan>[];
  for (final clip in track.midiClips) {
    spans.add(PresetPreviewClipSpan(
      name: '[MIDI] ${track.name}',
      kind: ClipContentKind.midi,
      startBeat: clip.startBeat,
      lengthBeats: clip.lengthBeats,
      notes: clip.notes,
      loopContent: clip.loopContent,
      contentLengthBeats: clip.loopContentLengthBeats,
    ));
  }
  for (final clip in track.sampleClips) {
    spans.add(PresetPreviewClipSpan(
      name: clip.sampleId.isNotEmpty ? clip.sampleId : '[Sample]',
      kind: ClipContentKind.sample,
      startBeat: clip.startBeat,
      lengthBeats: clip.lengthBeats,
    ));
  }
  for (final clip in track.automationClips) {
    spans.add(PresetPreviewClipSpan(
      name: '${clip.deviceId} ${clip.paramId}',
      kind: ClipContentKind.automation,
      startBeat: clip.startBeat,
      lengthBeats: clip.lengthBeats,
    ));
  }
  spans.sort((a, b) => a.startBeat.compareTo(b.startBeat));
  return spans;
}

double trackTimelineEndBeats(
  TrackSnapshot track, {
  required double loopRegionEndBeat,
}) {
  var maxEnd = loopRegionEndBeat > 4.0 ? loopRegionEndBeat : 4.0;
  void consider(double end) {
    if (end > maxEnd) maxEnd = end;
  }

  for (final c in track.midiClips) {
    consider(c.startBeat + c.lengthBeats);
    for (final n in c.notes) {
      consider(c.startBeat + n.startBeat + n.durationBeats);
    }
  }
  for (final c in track.sampleClips) {
    consider(c.startBeat + c.lengthBeats);
  }
  for (final c in track.automationClips) {
    consider(c.startBeat + c.lengthBeats);
  }
  return maxEnd;
}
