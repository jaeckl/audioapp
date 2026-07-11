part of 'device_chain_minimap.dart';

class _MinimapChainPreview extends StatelessWidget {
  const _MinimapChainPreview({
    required this.track,
    required this.density,
    required this.chainHeight,
  });

  final TrackSnapshot track;
  final DeviceStripSlotDensity density;
  final double chainHeight;

  @override
  Widget build(BuildContext context) {
    final devices = track.visibleDevices.toList();
    final contentWidth =
        DeviceChainLayout.contentWidth(track, density, horizontalPadding: 0);

    if (devices.isEmpty) {
      return ColoredBox(
        color: DeviceStripTheme.stripBackground,
        child: Center(
          child: Text(
            'No devices',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.white24),
          ),
        ),
      );
    }

    return ColoredBox(
      color: DeviceStripTheme.stripBackground,
      child: FittedBox(
        fit: BoxFit.fitHeight,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: contentWidth,
          height: chainHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < devices.length; i++) ...[
                if (density != DeviceStripSlotDensity.collapsed) ...[
                  const SizedBox(
                    width: DeviceStripMetrics.toolRailWidth,
                    child: ColoredBox(
                      color: DeviceStripTheme.toolRailBackground,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                                DeviceStripTheme.toolRailRadius),
                            bottomLeft: Radius.circular(
                                DeviceStripTheme.toolRailRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  width: density == DeviceStripSlotDensity.collapsed
                      ? DeviceChainLayout.slotWidthFor(devices[i], density)
                      : DeviceStripMetrics.designWidthFor(devices[i].type),
                  height: chainHeight,
                  child: DeviceStripCard(
                    deviceType: devices[i].type,
                    subtitle: null,
                    headerOnly: density == DeviceStripSlotDensity.collapsed,
                    attachToolRail: density != DeviceStripSlotDensity.collapsed,
                    bodyHeight: chainHeight -
                        DeviceStripTheme.cardChromeHeight -
                        DeviceStripTheme.cardBorderWidth * 2,
                    child: density == DeviceStripSlotDensity.collapsed
                        ? const SizedBox.shrink()
                        : const ColoredBox(
                            color: DeviceStripTheme.cardBackground),
                  ),
                ),
                SizedBox(
                  width: DeviceStripMetrics.separatorWidth,
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
