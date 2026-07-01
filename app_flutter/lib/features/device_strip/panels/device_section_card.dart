import 'package:flutter/material.dart';

import 'device_panel_theme.dart';

/// Rounded section container used across synth and FX filter blocks.
class DeviceSectionCard extends StatelessWidget {
  const DeviceSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
    this.backgroundColor,
    this.borderColor,
    this.clipPreview = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool clipPreview;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor ?? DevicePanelTheme.sectionBackground,
      borderRadius: BorderRadius.circular(DevicePanelTheme.sectionRadius),
      border: Border.all(color: borderColor ?? DevicePanelTheme.sectionBorder),
    );

    if (clipPreview) {
      return DecoratedBox(
        decoration: decoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DevicePanelTheme.sectionRadius),
          child: child,
        ),
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Preview slot with standard hero/strip sizing and chrome.
class DevicePreviewFrame extends StatelessWidget {
  const DevicePreviewFrame({
    super.key,
    required this.child,
    this.height = DevicePanelTheme.previewHeroHeight,
    this.borderColor,
  });

  final Widget child;
  final double height;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: DevicePanelTheme.previewDecoration(borderColor: borderColor),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DevicePanelTheme.sectionRadius),
          child: child,
        ),
      ),
    );
  }
}
