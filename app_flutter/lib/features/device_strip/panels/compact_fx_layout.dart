import 'package:flutter/material.dart';

import '../device_strip_metrics.dart';
import 'device_panel_theme.dart';
import 'device_section_card.dart';

/// Shared 216px FX card scaffold: optional preview, header, knob rows.
class CompactFxPage extends StatelessWidget {
  const CompactFxPage({
    super.key,
    this.preview,
    this.expandPreview = false,
    this.header,
    required this.rows,
    this.knobRowGap = DevicePanelTheme.knobRowGap,
  });

  final Widget? preview;
  final bool expandPreview;
  final Widget? header;
  final List<Widget> rows;
  final double knobRowGap;

  @override
  Widget build(BuildContext context) {
    final hPad = DeviceStripMetrics.dynamicsFxPanelPaddingH / 2;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (preview != null) ...[
            if (expandPreview)
              Expanded(
                child: DeviceSectionCard(
                  clipPreview: true,
                  padding: EdgeInsets.zero,
                  child: preview!,
                ),
              )
            else
              DevicePreviewFrame(child: preview!),
            const SizedBox(height: DevicePanelTheme.sectionGap),
          ],
          if (header != null) ...[
            header!,
            const SizedBox(height: DevicePanelTheme.sectionGap),
          ],
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: knobRowGap),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Three-slot knob row used by dynamics, time, and mood FX panels.
Widget compactFxKnobGridRow(List<Widget?> slots) {
  assert(slots.length == 3);
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < slots.length; i++) ...[
        if (i > 0) const SizedBox(width: DeviceStripMetrics.dynamicsFxKnobGap),
        SizedBox(
          width: DeviceStripMetrics.dynamicsFxKnobColumnWidth,
          child: Align(
            alignment: Alignment.topCenter,
            child: slots[i],
          ),
        ),
      ],
    ],
  );
}
