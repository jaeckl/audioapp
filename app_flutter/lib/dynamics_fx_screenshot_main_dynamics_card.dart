part of 'dynamics_fx_screenshot_main.dart';

Widget _dynamicsCard({
  required String type,
  required Widget panel,
}) {
  const cardHeight = DeviceStripMetrics.height;
  const bodyHeight = cardHeight - DeviceStripTheme.cardChromeHeight;
  final width = DeviceStripMetrics.designWidthFor(type);

  return SizedBox(
    width: width,
    height: cardHeight,
    child: DeviceStripCard(
      deviceType: type,
      subtitle: 'Stereo · FX',
      bodyHeight: bodyHeight,
      tabs: devicePanelTabsRepository.tabsFor(type),
      selectedTabIndex: 0,
      child: DeviceStripViewport(
        shrinkWrap: true,
        designWidth: width,
        designHeight: bodyHeight,
        child: panel,
      ),
    ),
  );
}
