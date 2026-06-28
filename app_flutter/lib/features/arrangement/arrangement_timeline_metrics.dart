// Timeline zoom and clip layout helpers for the arrangement view.
import 'dart:math' as math;

import '../../bridge/project_snapshot.dart';
import '../piano_roll/piano_roll_metrics.dart';

class ArrangementTimelineMetrics {
  static const double defaultPixelsPerBeat = 64;
  static const double minPixelsPerBeat = 28;
  static const double maxPixelsPerBeat = 200;
  static const double trackHeaderWidth = 44;
  static const double trackHeaderExpandedWidth = 168;
  static const double trackLaneHeight = 56;

  static bool headerShowsMixControls(double columnWidth) =>
      columnWidth > trackHeaderWidth + 8;
  /// Legacy minimum; prefer [virtualLengthBeats] for scroll width.
  static const double timelineBeats = 32;
  static const double minClipDisplayWidthPx = 16;
  static const double gridBeats = 1.0;
  static const double defaultMidiClipLengthBeats = 4.0;

  /// Furthest beat occupied by any clip (or loop length when enabled).
  static double contentEndBeat(ProjectSnapshot snapshot) {
    var end = 0.0;
    for (final track in snapshot.tracks) {
      for (final clip in track.midiClips) {
        end = math.max(end, clip.startBeat + clip.lengthBeats);
      }
      for (final clip in track.sampleClips) {
        end = math.max(end, clip.startBeat + clip.lengthBeats);
      }
      for (final clip in track.automationClips) {
        end = math.max(end, clip.startBeat + clip.lengthBeats);
      }
    }
    if (snapshot.loopEnabled) {
      end = math.max(end, snapshot.loopRegionEndBeat);
    }
    return end > 0 ? end : defaultMidiClipLengthBeats;
  }

  /// Scrollable timeline length — matches piano-roll virtual grid padding.
  static double virtualLengthBeats(ProjectSnapshot snapshot) {
    return PianoRollMetrics.virtualLengthBeats(contentEndBeat(snapshot));
  }

  /// Highlight end for the shared bar ruler (loop region end or song content).
  static double rulerRegionEndBeat(ProjectSnapshot snapshot) {
    if (snapshot.loopEnabled) {
      return snapshot.loopRegionEndBeat;
    }
    return contentEndBeat(snapshot);
  }

  static double rulerRegionStartBeat(ProjectSnapshot snapshot) {
    if (snapshot.loopEnabled) {
      return snapshot.loopRegionStartBeat;
    }
    return 0;
  }

  static double quantizeBeat(double beat, {double grid = gridBeats}) {
    if (grid <= 0) {
      return beat;
    }
    return (beat / grid).floor() * grid;
  }

  static bool clipsOverlap({
    required double aStartBeat,
    required double aLengthBeats,
    required double bStartBeat,
    required double bLengthBeats,
  }) {
    return aStartBeat < bStartBeat + bLengthBeats && bStartBeat < aStartBeat + aLengthBeats;
  }

  /// Quantized start beat at or after [desiredStartBeat] that fits without overlapping [existingClips].
  static double placementStartBeat({
    required double desiredStartBeat,
    required double clipLengthBeats,
    required List<({double start, double length})> existingClips,
    double timelineEndBeats = timelineBeats,
    double grid = gridBeats,
  }) {
    if (clipLengthBeats <= 0) {
      return quantizeBeat(desiredStartBeat.clamp(0.0, timelineEndBeats), grid: grid);
    }

    var start = quantizeBeat(desiredStartBeat.clamp(0.0, timelineEndBeats), grid: grid);
    for (var attempt = 0; attempt < 128; attempt++) {
      if (start + clipLengthBeats > timelineEndBeats) {
        final fallback = quantizeBeat(
          (timelineEndBeats - clipLengthBeats).clamp(0.0, timelineEndBeats),
          grid: grid,
        );
        final fallbackFree = !existingClips.any(
          (clip) => clipsOverlap(
            aStartBeat: fallback,
            aLengthBeats: clipLengthBeats,
            bStartBeat: clip.start,
            bLengthBeats: clip.length,
          ),
        );
        return fallbackFree ? fallback : start;
      }

      final conflict = existingClips.where(
        (clip) => clipsOverlap(
          aStartBeat: start,
          aLengthBeats: clipLengthBeats,
          bStartBeat: clip.start,
          bLengthBeats: clip.length,
        ),
      );
      if (conflict.isEmpty) {
        return start;
      }

      final nextStart = conflict
          .map((clip) => clip.start + clip.length)
          .reduce(math.max);
      start = quantizeBeat(nextStart, grid: grid);
    }
    return start;
  }

  static List<({double start, double length})> clipIntervalsForTrackExcluding(
    TrackSnapshot track, {
    String? excludeClipId,
  }) {
    return [
      ...track.midiClips
          .where((clip) => clip.id != excludeClipId)
          .map((clip) => (start: clip.startBeat, length: clip.lengthBeats)),
      ...track.sampleClips
          .where((clip) => clip.id != excludeClipId)
          .map((clip) => (start: clip.startBeat, length: clip.lengthBeats)),
      ...track.automationClips
          .where((clip) => clip.id != excludeClipId)
          .map((clip) => (start: clip.startBeat, length: clip.lengthBeats)),
    ];
  }

  static List<({double start, double length})> clipIntervalsForTrack(TrackSnapshot track) {
    return [
      ...track.midiClips.map((clip) => (start: clip.startBeat, length: clip.lengthBeats)),
      ...track.sampleClips.map((clip) => (start: clip.startBeat, length: clip.lengthBeats)),
      ...track.automationClips.map((clip) => (start: clip.startBeat, length: clip.lengthBeats)),
    ];
  }

  static double clampPixelsPerBeat(double value) {
    return value.clamp(minPixelsPerBeat, maxPixelsPerBeat);
  }

  /// Readable floor scales with zoom so pinch in/out changes clip width visibly.
  static double scaledMinClipWidthPx(double pixelsPerBeat) {
    return minClipDisplayWidthPx * (pixelsPerBeat / defaultPixelsPerBeat);
  }

  /// Visual clip width: beat-accurate length × zoom, with a zoom-scaled readable floor.
  static double clipDisplayWidthPx({
    required double startBeat,
    required double lengthBeats,
    required double pixelsPerBeat,
    required double gapEndBeat,
    double? viewportWidthPx,
  }) {
    final minWidthPx = scaledMinClipWidthPx(pixelsPerBeat);
    final startPx = startBeat * pixelsPerBeat;
    final naturalPx = lengthBeats * pixelsPerBeat;
    final gapEndPx = gapEndBeat * pixelsPerBeat;
    final availablePx = (gapEndPx - startPx).clamp(0.0, double.infinity);
    if (availablePx <= 0) {
      return naturalPx > 0 ? naturalPx : minWidthPx;
    }

    var width = math.max(naturalPx, minWidthPx);
    width = width.clamp(minWidthPx, availablePx);

    // At default zoom only: lone short clips may grow into empty lane space.
    if (pixelsPerBeat <= defaultPixelsPerBeat + 0.5 &&
        viewportWidthPx != null &&
        viewportWidthPx > minWidthPx &&
        naturalPx < viewportWidthPx * 0.35) {
      width = width.clamp(minWidthPx, math.max(width, math.min(availablePx, viewportWidthPx)));
    }

    return width;
  }

  static double gapEndBeatForClip({
    required double clipStartBeat,
    required List<double> otherClipStarts,
    required double timelineEndBeat,
  }) {
    var gapEnd = timelineEndBeat;
    for (final start in otherClipStarts) {
      if (start > clipStartBeat && start < gapEnd) {
        gapEnd = start;
      }
    }
    return gapEnd;
  }

  /// Visual width (in px) of a single clip on a track lane. Sample clips use
  /// the zoom-aware [clipDisplayWidthPx] (which adds a readable minimum and
  /// optional viewport fill); MIDI and automation clips render beat-accurate.
  ///
  /// Use this wherever the resize-handle must track the rendered clip's
  /// right edge instead of the beat-accurate end.
  static double renderedClipWidthPx({
    required ClipContentKind kind,
    required double startBeat,
    required double lengthBeats,
    required double pixelsPerBeat,
    required List<double> otherClipStarts,
    required double timelineEndBeat,
    double? viewportWidthPx,
  }) {
    switch (kind) {
      case ClipContentKind.sample:
        return clipDisplayWidthPx(
          startBeat: startBeat,
          lengthBeats: lengthBeats,
          pixelsPerBeat: pixelsPerBeat,
          gapEndBeat: gapEndBeatForClip(
            clipStartBeat: startBeat,
            otherClipStarts: otherClipStarts,
            timelineEndBeat: timelineEndBeat,
          ),
          viewportWidthPx: viewportWidthPx,
        );
      case ClipContentKind.midi:
      case ClipContentKind.automation:
        return lengthBeats * pixelsPerBeat;
    }
  }
}
