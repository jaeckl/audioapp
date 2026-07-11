import 'package:flutter/material.dart';

import 'device_strip_theme.dart';
import 'device_tab_bar.dart';

part 'device_header_tab_bar_device_header_tab.dart';

/// Flat header tabs for the device container — selected tab uses a dark top-rounded fill.
class DeviceHeaderTabBar extends StatelessWidget {
  const DeviceHeaderTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.accentColor,
    this.compact = false,
  });

  final List<DeviceTabSpec> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color? accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeviceStripTheme.headerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < tabs.length; index++)
            _DeviceHeaderTab(
              tab: tabs[index],
              selected: index == selectedIndex,
              accentColor: accentColor ?? DeviceStripTheme.genericAccent,
              compact: compact,
              onTap: () => onSelected(index),
            ),
        ],
      ),
    );
  }
}
