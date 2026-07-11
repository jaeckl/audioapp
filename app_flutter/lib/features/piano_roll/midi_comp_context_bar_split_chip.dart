part of 'midi_comp_context_bar.dart';

class _SplitChip extends StatelessWidget {
  const _SplitChip({required this.beatLabel, required this.onTap});

  final String beatLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ArrangementLoopRegionTheme.color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.call_split, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Split ${beatLabel}b',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
