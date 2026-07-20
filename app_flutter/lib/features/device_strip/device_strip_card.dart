import 'package:flutter/material.dart';

import 'device_header_tab_bar.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';

part 'device_strip_card_container_tab_header.dart';
part 'device_strip_card_header_bar.dart';
part 'device_strip_card_header_panel.dart';
part 'device_strip_card_header_text.dart';

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
    this.headerActions,
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
  final Widget? headerActions;

  bool get _usesContainerTabs =>
      !headerOnly && (tabs.isNotEmpty || headerActions != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = DeviceStripTheme.accentForDeviceType(deviceType);
    // Filter: tool rail already shows name; keep blank header strip for chrome.
    final label = deviceType == 'filter'
        ? ''
        : DeviceStripTheme.labelForDeviceType(deviceType);
    final radius = const Radius.circular(DeviceStripTheme.cardRadius);

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
          left:
              attachInputPanel || attachToolRail ? BorderSide.none : borderSide,
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
                          actions: headerActions,
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
                        // Soft cast from header onto the face (body paints
                        // after header, so shadow lives here, not on header).
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            child,
                            const Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 5,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x73000000),
                                        Color(0x00000000),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
