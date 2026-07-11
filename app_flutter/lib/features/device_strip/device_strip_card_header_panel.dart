part of 'device_strip_card.dart';

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({
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
    return ColoredBox(
      color: DeviceStripTheme.cardHeader,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _HeaderText(
            theme: theme,
            accent: accent,
            label: label,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }
}
