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
