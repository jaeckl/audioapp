import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../devices/frequency/mb_split_layout.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'split_branch_toggle_button.dart';

part 'multiband_split_panel_band_column.dart';
part 'multiband_crossover_editor.dart';

/// Body of a [MultibandSplitDeviceSnapshot]: band columns (toggle + gain) on
/// top, interactable log-Hz crossover editor below.
class MultibandSplitPanel extends StatelessWidget {
  const MultibandSplitPanel({
    super.key,
    required this.device,
    required this.onChanged,
    required this.onToggleBand,
    this.expandedBands = const {},
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

  final MultibandSplitDeviceSnapshot device;
  final void Function(String, double) onChanged;
  final void Function(int bandIndex) onToggleBand;
  final Set<int> expandedBands;
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
    final labels = MultibandSplitDeviceSnapshot.bandLabels(device.bandCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < device.bandCount; i++) ...[
                if (i > 0) const SizedBox(width: MbSplitLayout.colGap),
                bandColumn(
                  bandIndex: i,
                  label: labels[i],
                  expanded: expandedBands.contains(i),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: MultibandCrossoverEditor(
              bandCount: device.bandCount,
              crossoverHz: device.crossoverHz,
              accent: accent,
              onCrossoverChanged: (index, hz) =>
                  onChanged('crossover$index', hz),
            ),
          ),
        ],
      ),
    );
  }
}
