import 'device_tab_bar.dart';
import 'generated_device_panel_tabs.dart';

/// Lookup backed by panel-owned, generated device registrations.
final class DevicePanelTabsRepository {
  const DevicePanelTabsRepository();

  List<DeviceTabSpec> tabsFor(String deviceType) =>
      generatedDevicePanelTabs[deviceType] ?? const <DeviceTabSpec>[];
}

const devicePanelTabsRepository = DevicePanelTabsRepository();
