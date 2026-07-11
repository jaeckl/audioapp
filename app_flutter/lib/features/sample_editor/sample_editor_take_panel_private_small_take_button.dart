part of 'sample_editor_take_panel.dart';

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
