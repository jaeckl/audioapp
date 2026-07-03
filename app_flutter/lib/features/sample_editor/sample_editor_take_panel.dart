import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../arrangement/arrangement_loop_region_marker.dart';

const double sampleEditorTakeLaneHeight = 58;

class SampleEditorTakeTrackLanes extends StatelessWidget {
  const SampleEditorTakeTrackLanes({
    super.key,
    required this.takes,
    required this.regions,
    required this.clipLengthBeats,
    required this.samples,
    required this.onTakeAtBeat,
  });

  final List<SampleClipTakeSnapshot> takes;
  final List<SampleClipTakeRegionSnapshot> regions;
  final double clipLengthBeats;
  final List<SampleLibraryEntrySnapshot> samples;
  final void Function(double beat, String takeId) onTakeAtBeat;

  @override
  Widget build(BuildContext context) {
    final sampleById = {for (final sample in samples) sample.id: sample};
    return Column(
      children: [
        for (final take in takes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _TakeWaveLane(
              take: take,
              peaks: sampleById[take.sampleId]?.waveformPeaks ?? const [],
              regions: regions,
              clipLengthBeats: clipLengthBeats,
              onBeatTap: (beat) => onTakeAtBeat(beat, take.id),
            ),
          ),
      ],
    );
  }
}

class SampleEditorTakeToolsPanel extends StatelessWidget {
  const SampleEditorTakeToolsPanel({
    super.key,
    required this.playheadBeat,
    required this.selectedMarkerBeat,
    required this.onSplitAtPlayhead,
    required this.onDeleteSelected,
    required this.onNudgeSelected,
  });

  final double playheadBeat;
  final double? selectedMarkerBeat;
  final VoidCallback onSplitAtPlayhead;
  final VoidCallback onDeleteSelected;
  final ValueChanged<int> onNudgeSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COMPING',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .7)),
                      SizedBox(height: 3),
                      Text('Edit comp markers, then tap take lane for segment.',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  _BeatBadge(label: '${playheadBeat.toStringAsFixed(2)}b'),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TakeSplitButton(
                      beatLabel: '${playheadBeat.toStringAsFixed(2)}b',
                      onTap: onSplitAtPlayhead,
                    ),
                    _SelectedMarkerTile(beat: selectedMarkerBeat),
                    _SmallTakeButton(
                      icon: Icons.chevron_left,
                      label: 'NUDGE -',
                      enabled: selectedMarkerBeat != null,
                      onTap: () => onNudgeSelected(-1),
                    ),
                    _SmallTakeButton(
                      icon: Icons.chevron_right,
                      label: 'NUDGE +',
                      enabled: selectedMarkerBeat != null,
                      onTap: () => onNudgeSelected(1),
                    ),
                    _SmallTakeButton(
                      icon: Icons.delete_outline,
                      label: 'DELETE',
                      enabled: selectedMarkerBeat != null,
                      onTap: onDeleteSelected,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

class _BeatBadge extends StatelessWidget {
  const _BeatBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .045),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Text('PLAYHEAD $label',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .4)),
      );
}

class _TakeSplitButton extends StatelessWidget {
  const _TakeSplitButton({required this.beatLabel, required this.onTap});

  final String beatLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        height: 86,
        child: Material(
          color: ArrangementLoopRegionTheme.color.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: ArrangementLoopRegionTheme.color
                        .withValues(alpha: .45)),
              ),
              child: Row(children: [
                const Icon(Icons.call_split, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Split At Playhead',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Create boundary at $beatLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _SelectedMarkerTile extends StatelessWidget {
  const _SelectedMarkerTile({required this.beat});

  final double? beat;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 130,
        height: 66,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .07)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SELECTED MARKER',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5)),
                Text(beat == null ? 'None' : '${beat!.toStringAsFixed(2)}b',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: beat == null ? Colors.white38 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
              ]),
        ),
      );
}

class _SmallTakeButton extends StatelessWidget {
  const _SmallTakeButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 92,
        height: 66,
        child: Material(
          color: Colors.white.withValues(alpha: enabled ? .055 : .025),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: enabled ? .10 : .04)),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        color: enabled ? Colors.white70 : Colors.white24,
                        size: 19),
                    const SizedBox(height: 5),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: enabled ? Colors.white70 : Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
                  ]),
            ),
          ),
        ),
      );
}

class _TakeWaveLane extends StatelessWidget {
  const _TakeWaveLane({
    required this.take,
    required this.peaks,
    required this.regions,
    required this.clipLengthBeats,
    required this.onBeatTap,
  });

  final SampleClipTakeSnapshot take;
  final List<double> peaks;
  final List<SampleClipTakeRegionSnapshot> regions;
  final double clipLengthBeats;
  final ValueChanged<double> onBeatTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (clipLengthBeats <= 0 || constraints.maxWidth <= 0) return;
            final beat = (details.localPosition.dx / constraints.maxWidth) *
                clipLengthBeats;
            onBeatTap(beat);
          },
          child: Container(
            height: sampleEditorTakeLaneHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .035),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.white.withValues(alpha: .075)),
            ),
            child: Stack(children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TakeWavePainter(
                    peaks: peaks,
                    take: take,
                    regions: regions,
                    clipLengthBeats: clipLengthBeats,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 7,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .42),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .08)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(take.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    Text('${take.lengthBeats.toStringAsFixed(2)}b',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 9)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _TakeWavePainter extends CustomPainter {
  const _TakeWavePainter({
    required this.peaks,
    required this.take,
    required this.regions,
    required this.clipLengthBeats,
  });

  final List<double> peaks;
  final SampleClipTakeSnapshot take;
  final List<SampleClipTakeRegionSnapshot> regions;
  final double clipLengthBeats;

  double _peakAt(double position) {
    if (peaks.isEmpty) return 0;
    final source = position.clamp(0.0, 1.0) * (peaks.length - 1);
    final lo = source.floor();
    final hi = math.min(peaks.length - 1, lo + 1);
    final t = source - lo;
    return (peaks[lo] + (peaks[hi] - peaks[lo]) * t).abs().clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    final unavailable = Paint()
      ..color = Colors.black.withValues(alpha: .28)
      ..style = PaintingStyle.fill;
    final regionLine = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..strokeWidth = 1;
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: .30)
      ..strokeWidth = 1;
    final active = Paint()
      ..color = ArrangementLoopRegionTheme.color.withValues(alpha: .22)
      ..style = PaintingStyle.fill;
    final activeBorder = Paint()
      ..color = ArrangementLoopRegionTheme.color.withValues(alpha: .70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (clipLengthBeats > 0) {
      final availableLeft =
          (take.startBeatOffset / clipLengthBeats).clamp(0.0, 1.0) * size.width;
      final availableRight =
          ((take.startBeatOffset + take.lengthBeats) / clipLengthBeats)
                  .clamp(0.0, 1.0) *
              size.width;
      if (availableLeft > 0) {
        canvas.drawRect(
            Rect.fromLTRB(0, 0, availableLeft, size.height), unavailable);
      }
      if (availableRight < size.width) {
        canvas.drawRect(
            Rect.fromLTRB(availableRight, 0, size.width, size.height),
            unavailable);
      }

      for (final region in regions) {
        if (region.takeId != take.id) continue;
        final left =
            (region.startBeat / clipLengthBeats).clamp(0.0, 1.0) * size.width;
        final right =
            (region.endBeat / clipLengthBeats).clamp(0.0, 1.0) * size.width;
        if (right <= left) continue;
        final rect = Rect.fromLTRB(left, 5, right, size.height - 5);
        final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(7));
        canvas.drawRRect(rounded, active);
        canvas.drawRRect(rounded, activeBorder);
      }
    }

    if (peaks.isEmpty) {
      canvas.drawLine(Offset(0, center), Offset(size.width, center), wave);
    } else {
      final samples = math.max(size.width.ceil(), 128).clamp(128, 2048);
      for (var i = 0; i <= samples; i++) {
        final p = i / samples;
        final x = p * size.width;
        final peak = _peakAt(p);
        final half = 4 + peak * (size.height * .36);
        canvas.drawLine(
            Offset(x, center - half), Offset(x, center + half), wave);
      }
    }

    if (clipLengthBeats <= 0) return;
    for (final region in regions) {
      final x =
          (region.startBeat / clipLengthBeats).clamp(0.0, 1.0) * size.width;
      canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), regionLine);
    }
  }

  @override
  bool shouldRepaint(covariant _TakeWavePainter oldDelegate) =>
      oldDelegate.peaks != peaks ||
      oldDelegate.take != take ||
      oldDelegate.regions != regions ||
      oldDelegate.clipLengthBeats != clipLengthBeats;
}
