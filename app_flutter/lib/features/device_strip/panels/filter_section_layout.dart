import 'package:flutter/material.dart';

import '../device_strip_metrics.dart';
import '../device_strip_theme.dart';
import 'device_panel_theme.dart';
import 'device_section_card.dart';

part 'filter_section_layout_filter_section_tier.dart';

/// Filter-like face: black hero fills the card body; response curve/grid only
/// paint above the floating control plate.
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

  /// Inset around the floating plate (black shows through).
  static const _plateInset = 6.0;

  @override
  Widget build(BuildContext context) {
    final hPad =
        padding?.horizontal ?? DeviceStripMetrics.dynamicsFxPanelPaddingH / 2;
    final edgePadding = padding ?? EdgeInsets.fromLTRB(hPad, 4, hPad, 4);

    Widget controlBlock = controls;
    if (wrapControlsInCard) {
      controlBlock = DeviceSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!,
                  textAlign: TextAlign.center,
                  style: DevicePanelTheme.sectionLabel),
              const SizedBox(height: 4),
            ],
            modeSelector,
            const SizedBox(height: 5),
            Expanded(child: controls),
          ],
        ),
      );
    }

    if (preview == null || tier == FilterSectionTier.embedded) {
      return Padding(
        padding: edgePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!wrapControlsInCard) ...[
              if (title != null) ...[
                Text(title!,
                    textAlign: TextAlign.center,
                    style: DevicePanelTheme.sectionLabel),
                const SizedBox(height: 4),
              ],
              modeSelector,
              const SizedBox(height: DevicePanelTheme.sectionGap),
              Expanded(child: Center(child: controlBlock)),
            ] else
              Expanded(child: controlBlock),
          ],
        ),
      );
    }

    final plate = DecoratedBox(
      decoration: BoxDecoration(
        color: DeviceStripTheme.panelElevated,
        borderRadius: BorderRadius.circular(DevicePanelTheme.sectionRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            modeSelector,
            const SizedBox(height: 2),
            controls,
          ],
        ),
      ),
    );

    // Black fills entire body. Graph only lives in Expanded above the plate.
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: DevicePanelTheme.heroScreen),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: preview!),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _plateInset,
                0,
                _plateInset,
                _plateInset,
              ),
              child: plate,
            ),
          ],
        ),
      ],
    );
  }
}
