part of 'track_mute_row.dart';

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.color,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? color : const Color(0xFF1C1C20),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? Colors.black : PlayDeckTheme.optionLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
