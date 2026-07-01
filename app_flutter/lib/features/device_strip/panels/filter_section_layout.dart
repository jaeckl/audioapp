import 'package:flutter/material.dart';

import '../device_strip_metrics.dart';
import 'device_panel_theme.dart';
import 'device_section_card.dart';

enum FilterSectionTier { hero, strip, embedded }

/// Standard filter block layout: preview → mode row → controls.
class FilterSectionLayout extends StatelessWidget {
  const FilterSectionLayout({
    super.key,
    required this.modeSelector,
    required this.controls,
    this.preview,
    this.tier = FilterSectionTier.hero,
    this.title,
    this.padding,
    this.wrapControlsInCard = false,
  });

  final Widget? preview;
  final Widget modeSelector;
  final Widget controls;
  final FilterSectionTier tier;
  final String? title;
  final EdgeInsets? padding;
  final bool wrapControlsInCard;

  @override
  Widget build(BuildContext context) {
    final hPad = padding?.horizontal ??
        DeviceStripMetrics.dynamicsFxPanelPaddingH / 2;
    final edgePadding = padding ??
        EdgeInsets.fromLTRB(hPad, 6, hPad, 4);

    final previewHeight = switch (tier) {
      FilterSectionTier.hero => DevicePanelTheme.previewHeroHeight,
      FilterSectionTier.strip => DevicePanelTheme.previewStripHeight,
      FilterSectionTier.embedded => null,
    };

    Widget controlBlock = controls;
    if (wrapControlsInCard) {
      controlBlock = DeviceSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, textAlign: TextAlign.center, style: DevicePanelTheme.sectionLabel),
              const SizedBox(height: 4),
            ],
            modeSelector,
            const SizedBox(height: 5),
            Expanded(child: controls),
          ],
        ),
      );
    }

    return Padding(
      padding: edgePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (preview != null && previewHeight != null) ...[
            DevicePreviewFrame(height: previewHeight, child: preview!),
            const SizedBox(height: DevicePanelTheme.sectionGap),
          ],
          if (!wrapControlsInCard) ...[
            if (title != null) ...[
              Text(title!, textAlign: TextAlign.center, style: DevicePanelTheme.sectionLabel),
              const SizedBox(height: 4),
            ],
            modeSelector,
            const SizedBox(height: DevicePanelTheme.sectionGap),
            controlBlock,
          ] else
            Expanded(child: controlBlock),
        ],
      ),
    );
  }
}
