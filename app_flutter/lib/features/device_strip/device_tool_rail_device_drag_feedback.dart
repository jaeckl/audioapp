part of 'device_tool_rail.dart';

class _DeviceDragFeedback extends StatelessWidget {
  const _DeviceDragFeedback({
    required this.deviceName,
    required this.accentColor,
  });

  final String deviceName;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DeviceStripTheme.toolRailBackground,
          borderRadius: BorderRadius.circular(DeviceStripTheme.toolRailRadius),
          border: Border.all(color: accentColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: SizedBox(
          width: DeviceStripMetrics.toolRailWidth,
          height: 120,
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                deviceName.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
