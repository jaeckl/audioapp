part of 'track_mute_row.dart';

class _TrackChip extends StatelessWidget {
  const _TrackChip({
    required this.name,
    required this.selected,
    required this.muted,
    required this.soloed,
    required this.onSelect,
    required this.onMute,
    required this.onSolo,
  });

  final String name;
  final bool selected;
  final bool muted;
  final bool soloed;
  final VoidCallback onSelect;
  final VoidCallback onMute;
  final VoidCallback onSolo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2D2D3A) : PlayDeckTheme.optionIdle,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  color: PlayDeckTheme.optionLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              _MiniButton(
                  label: 'M',
                  active: muted,
                  onTap: onMute,
                  color: Colors.redAccent),
              const SizedBox(width: 4),
              _MiniButton(
                  label: 'S',
                  active: soloed,
                  onTap: onSolo,
                  color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }
}
