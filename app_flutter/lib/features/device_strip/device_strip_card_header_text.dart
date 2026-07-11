part of 'device_strip_card.dart';

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.theme,
    required this.accent,
    required this.label,
    this.subtitle,
  });

  final ThemeData theme;
  final Color accent;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
