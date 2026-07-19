import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../devices/frequency/spectral_loud_split_layout.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_vu_meter.dart';
import 'split_branch_toggle_button.dart';

part 'spectral_loud_split_panel_preview.dart';
part 'spectral_loud_split_panel_band_row.dart';

/// Two-column body: live spectral preview | three loud/mid/quiet rows.
class SpectralLoudSplitPanel extends StatelessWidget {
  const SpectralLoudSplitPanel({
    super.key,
    required this.device,
    required this.onChanged,
    required this.onToggleBand,
    this.expandedBands = const {},
    this.spectrum = const [],
    this.bandLevels = const [0, 0, 0],
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final SpectralLoudSplitDeviceSnapshot device;
  final void Function(String, double) onChanged;
  final void Function(int bandIndex) onToggleBand;
  final Set<int> expandedBands;
  final List<double> spectrum;
  final List<double> bandLevels;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int? connectModeLfoId;
  final void Function(String, double)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  Color get accent => DeviceStripTheme.accentForDeviceType(device.type);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        children: [
          Expanded(
            child: SpectralLoudPreview(
              spectrum: spectrum,
              highDb: device.highDb,
              lowDb: device.lowDb,
              accent: accent,
              onHighDb: (v) => onChanged('highDb', v),
              onLowDb: (v) => onChanged('lowDb', v),
            ),
          ),
          const SizedBox(width: SpectralLoudSplitLayout.colGap),
          SizedBox(
            width: SpectralLoudSplitLayout.controlsWidth,
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  Expanded(
                    child: bandRow(
                      bandIndex: i,
                      label: SpectralLoudSplitDeviceSnapshot.bandLabels[i],
                      expanded: expandedBands.contains(i),
                      level: i < bandLevels.length ? bandLevels[i] : 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
