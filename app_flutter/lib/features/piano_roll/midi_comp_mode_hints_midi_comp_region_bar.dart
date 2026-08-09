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

  static const barHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final region = MidiTakeColor.regionAtBeat(regions, playheadBeat);
    final takeName = region == null ? '—' : _takeName(region.takeId);
    final accent = region == null
        ? MidiTakeColor.fallback
        : MidiTakeColor.forTakeId(region.takeId, takes);
    return ColoredBox(
      color: PianoRollTheme.background,
      child: SizedBox(
        height: barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$takeName · ${playheadBeat.toStringAsFixed(2)}b',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PianoRollTheme.labelMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final entry in takes.indexed) ...[
                        if (entry.$1 > 0) const SizedBox(width: 6),
                        _TakeLegendChip(
                          label: entry.$2.name,
                          color: MidiTakeColor.forIndex(entry.$1),
                          active: region?.takeId == entry.$2.id,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _takeName(String takeId) {
    for (final take in takes) {
      if (take.id == takeId) return take.name;
    }
    return 'Take ?';
  }
}

class _TakeLegendChip extends StatelessWidget {
  const _TakeLegendChip({
    required this.label,
    required this.color,
    required this.active,
  });

  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.28 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.9 : 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : PianoRollTheme.labelMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
