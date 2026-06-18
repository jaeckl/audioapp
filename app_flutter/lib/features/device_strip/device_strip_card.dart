import 'package:flutter/material.dart';

import 'device_header_tab_bar.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';

/// Visible card container for one device in the horizontal chain.
class DeviceStripCard extends StatelessWidget {
  const DeviceStripCard({
    super.key,
    required this.deviceType,
    required this.bodyHeight,
    required this.child,
    this.subtitle,
    this.headerOnly = false,
    this.attachToolRail = false,
    this.attachInputPanel = false,
    this.attachOutputPanel = false,
    this.tabs = const [],
    this.selectedTabIndex = 0,
    this.onTabSelected,
  });

  final String deviceType;
  final double bodyHeight;
  final Widget child;
  final String? subtitle;

  /// When true, renders a compact name panel without a body section.
  final bool headerOnly;

  /// When true, omits the left border where a tool rail is attached.
  final bool attachToolRail;

  /// When true, omits the left border where an input panel is attached.
  final bool attachInputPanel;

  /// When true, omits the right border where an output panel is attached.
  final bool attachOutputPanel;

  final List<DeviceTabSpec> tabs;
  final int selectedTabIndex;
  final ValueChanged<int>? onTabSelected;

  bool get _usesContainerTabs => !headerOnly && tabs.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = DeviceStripTheme.accentForDeviceType(deviceType);
    final label = DeviceStripTheme.labelForDeviceType(deviceType);
    final radius = Radius.circular(DeviceStripTheme.cardRadius);

    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );

    final cardRadius = BorderRadius.only(topLeft: radius, topRight: radius);

    return Container(
      decoration: BoxDecoration(
        color: DeviceStripTheme.cardBackground,
        borderRadius: cardRadius,
        border: Border(
          top: borderSide,
          left: attachInputPanel || attachToolRail ? BorderSide.none : borderSide,
          bottom: borderSide,
        ),
      ),
      foregroundDecoration: attachOutputPanel
          ? null
          : BoxDecoration(
              borderRadius: cardRadius,
              border: const Border(right: borderSide),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: accent,
            child: const SizedBox(width: DeviceStripTheme.accentStripeWidth),
          ),
          Expanded(
            child: headerOnly
                ? _HeaderPanel(
                    theme: theme,
                    accent: accent,
                    label: label,
                    subtitle: subtitle,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_usesContainerTabs)
                        _ContainerTabHeader(
                          tabs: tabs,
                          selectedTabIndex: selectedTabIndex,
                          accent: accent,
                          onTabSelected: onTabSelected,
                        )
                      else
                        _HeaderBar(
                          theme: theme,
                          accent: accent,
                          label: label,
                          subtitle: subtitle,
                        ),
                      SizedBox(
                        height: bodyHeight,
                        child: child,
                      ),
                    ],
                  ),
          ),
          if (attachOutputPanel)
            ColoredBox(
              color: accent,
              child: const SizedBox(width: DeviceStripTheme.accentStripeWidth),
            ),
        ],
      ),
    );
  }
}

class _ContainerTabHeader extends StatelessWidget {
  const _ContainerTabHeader({
    required this.tabs,
    required this.selectedTabIndex,
    required this.accent,
    required this.onTabSelected,
  });

  final List<DeviceTabSpec> tabs;
  final int selectedTabIndex;
  final Color accent;
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeviceStripTheme.headerHeight,
      child: ColoredBox(
        color: DeviceStripTheme.cardHeader,
        child: DeviceHeaderTabBar(
          tabs: tabs,
          selectedIndex: selectedTabIndex,
          accentColor: accent,
          onSelected: onTabSelected ?? (_) {},
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.theme,
    required this.accent,
    required this.label,
    this.subtitle,
  });

  final ThemeData theme;
  final Color accent;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DeviceStripTheme.headerHeight,
      color: DeviceStripTheme.cardHeader,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: _HeaderText(
        theme: theme,
        accent: accent,
        label: label,
        subtitle: subtitle,
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({
    required this.theme,
    required this.accent,
    required this.label,
    this.subtitle,
  });

  final ThemeData theme;
  final Color accent;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DeviceStripTheme.cardHeader,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _HeaderText(
            theme: theme,
            accent: accent,
            label: label,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.theme,
    required this.accent,
    required this.label,
    this.subtitle,
  });

  final ThemeData theme;
  final Color accent;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
