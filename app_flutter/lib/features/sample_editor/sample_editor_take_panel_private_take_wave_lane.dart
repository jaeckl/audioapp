part of 'sample_editor_take_panel.dart';

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
