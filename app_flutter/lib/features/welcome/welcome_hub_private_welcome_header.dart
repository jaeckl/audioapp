part of 'welcome_hub.dart';

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: WelcomeTheme.accentSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: WelcomeTheme.accent.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.graphic_eq_rounded,
                  size: 28, color: WelcomeTheme.accent),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AudioApp',
                  style: TextStyle(
                    color: WelcomeTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Make something worth replaying',
                  style: TextStyle(color: WelcomeTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      );
}
