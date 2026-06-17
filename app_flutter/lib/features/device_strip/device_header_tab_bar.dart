import 'package:flutter/material.dart';

import 'device_strip_theme.dart';
import 'device_tab_bar.dart';

/// Flat header tabs for the device container — selected tab uses a dark top-rounded fill.
class DeviceHeaderTabBar extends StatelessWidget {
  const DeviceHeaderTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.accentColor,
  });

  final List<DeviceTabSpec> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color? accentColor;

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
              onTap: () => onSelected(index),
            ),
        ],
      ),
    );
  }
}

class _DeviceHeaderTab extends StatelessWidget {
  const _DeviceHeaderTab({
    required this.tab,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final DeviceTabSpec tab;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  static const _topRadius = Radius.circular(8);

  @override
  Widget build(BuildContext context) {
    final labelColor = selected ? Colors.white : Colors.white54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          topLeft: _topRadius,
          topRight: _topRadius,
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.black.withValues(alpha: 0.38) : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: _topRadius,
              topRight: _topRadius,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 15,
                color: selected ? accentColor : labelColor,
              ),
              const SizedBox(width: 5),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
