part of 'device_strip_chrome_panels.dart';

class _ChromeOutputShell extends StatelessWidget {
  const _ChromeOutputShell({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );
    final rightRadius = const Radius.circular(DeviceStripTheme.toolRailRadius);

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DeviceStripTheme.toolRailBackground,
          borderRadius: BorderRadius.only(
              topRight: rightRadius, bottomRight: rightRadius),
          border: const Border(
            top: borderSide,
            bottom: borderSide,
            right: borderSide,
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
