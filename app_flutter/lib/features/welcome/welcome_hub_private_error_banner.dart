part of 'welcome_hub.dart';

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WelcomeTheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: WelcomeTheme.error.withValues(alpha: 0.4)),
        ),
        child: Text(message,
            style: const TextStyle(color: WelcomeTheme.error, fontSize: 13)),
      );
}
