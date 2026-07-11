part of 'device_strip_chrome_panels.dart';

class RoutingOutputPanel extends StatelessWidget {
  const RoutingOutputPanel({super.key, required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) => _ChromeOutputShell(
        width: DeviceStripMetrics.routingOutputPanelWidth,
        child: Center(
          child: Icon(Icons.chevron_right, size: 18, color: accentColor),
        ),
      );
}
