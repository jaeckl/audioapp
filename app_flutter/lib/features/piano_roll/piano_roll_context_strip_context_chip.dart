part of 'piano_roll_context_strip.dart';

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: PianoRollTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3B3B49)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: PianoRollTheme.label,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// Flat tappable status text — not a chip/button.
class _ContextLabel extends StatelessWidget {
  const _ContextLabel({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _FlatCloseLabel extends StatelessWidget {
  const _FlatCloseLabel({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Icon(
          Icons.close,
          size: 18,
          color: PianoRollTheme.labelMuted,
        ),
      ),
    );
  }
}
