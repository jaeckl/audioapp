import '../../bridge/project_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';

/// Width/layout helpers for the horizontal device chain.
abstract final class DeviceChainLayout {
  static double slotWidthFor(DeviceSnapshot device, DeviceStripSlotDensity density) {
    final cardWidth = DeviceStripMetrics.designWidthFor(
      device.type,
      collapsed: density == DeviceStripSlotDensity.collapsed,
    );
    if (density == DeviceStripSlotDensity.collapsed) {
      return cardWidth;
    }
    return cardWidth + DeviceStripMetrics.toolRailWidth;
  }

  /// Total scrollable content width including list horizontal padding.
  static double contentWidth(
    TrackSnapshot track,
    DeviceStripSlotDensity density, {
    double horizontalPadding = 16,
  }) {
    final devices = track.visibleDevices.toList();
    if (devices.isEmpty) {
      return DeviceStripMetrics.separatorWidth + 120 + horizontalPadding;
    }

    var width = horizontalPadding;
    for (final device in devices) {
      width += slotWidthFor(device, density) + DeviceStripMetrics.separatorWidth;
    }
    return width;
  }
}
