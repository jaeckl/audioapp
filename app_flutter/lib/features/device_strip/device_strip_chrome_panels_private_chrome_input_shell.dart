part of 'device_strip_chrome_panels.dart';

class _ChromeInputShell extends StatelessWidget {
  const _ChromeInputShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );

    return SizedBox(
      width: DeviceStripMetrics.dynamicsInputPanelWidth,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: DeviceStripTheme.toolRailBackground,
          border: Border(
            top: borderSide,
            bottom: borderSide,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}
