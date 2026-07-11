part of 'device_strip_card.dart';

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
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
    return Container(
      height: DeviceStripTheme.headerHeight,
      color: DeviceStripTheme.cardHeader,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: _HeaderText(
        theme: theme,
        accent: accent,
        label: label,
        subtitle: subtitle,
      ),
    );
  }
}
