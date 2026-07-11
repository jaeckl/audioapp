part of 'midi_comp_mode_hints.dart';

class MidiCompRegionBar extends StatelessWidget {
  const MidiCompRegionBar({
    super.key,
    required this.playheadBeat,
    required this.takes,
    required this.regions,
  });

  final double playheadBeat;
  final List<MidiClipTakeSnapshot> takes;
  final List<MidiClipTakeRegionSnapshot> regions;

  static const barHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    final region = _regionAtBeat(playheadBeat);
    final takeName = region == null ? '—' : _takeName(region.takeId);
    return ColoredBox(
      color: PianoRollTheme.background,
      child: SizedBox(
        height: barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.layers,
                size: 16,
                color: const Color(0xFFFF6D8A).withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Region at ${playheadBeat.toStringAsFixed(2)}b uses $takeName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PianoRollTheme.labelMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Text(
                'Tap lane to comp',
                style: TextStyle(
                  color: PianoRollTheme.labelMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MidiClipTakeRegionSnapshot? _regionAtBeat(double beat) {
    for (var i = 0; i < regions.length; i++) {
      final region = regions[i];
      final isLast = i == regions.length - 1;
      if (beat >= region.startBeat &&
          (beat < region.endBeat || (isLast && beat <= region.endBeat))) {
        return region;
      }
    }
    return null;
  }

  String _takeName(String takeId) {
    for (final take in takes) {
      if (take.id == takeId) return take.name;
    }
    return 'Take ?';
  }
}
