part of 'welcome_recent_projects_panel.dart';

class _ExampleBadge extends StatelessWidget {
  const _ExampleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: WelcomeTheme.accentSoft,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: WelcomeTheme.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: WelcomeTheme.accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );
}
