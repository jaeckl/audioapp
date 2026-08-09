part of 'octave_panel.dart';

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected ? PlayDeckTheme.optionActive : PlayDeckTheme.optionIdle,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.black : PlayDeckTheme.optionLabel,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
