import 'package:flutter/material.dart';

import '../../bridge/live_meters_dto.dart';
import '../../bridge/project_snapshot.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_vu_meter.dart';
import 'split_branch_toggle_button.dart';

part 'split_device_panel_branch_row.dart';
part 'split_device_panel_path_painter.dart';

/// Body of an [SplitDeviceSnapshot] device: fork graphic → two branch rows
/// (toggle, solo, gain, VU) → merge graphic. Path endpoints track knob centers.
class SplitDevicePanel extends StatelessWidget {
  const SplitDevicePanel({
    super.key,
    required this.device,
    required this.onChanged,
    required this.onToggleBranch,
    this.branch0Expanded = false,
    this.branch1Expanded = false,
    this.liveMeter,
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

  final SplitDeviceSnapshot device;
  final void Function(String, double) onChanged;
  final void Function(int branchIndex) onToggleBranch;
  final bool branch0Expanded;
  final bool branch1Expanded;
  final DeviceMeterReading? liveMeter;
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            // Knob centers — same Y for both path rails and branch placement.
            final topY = h * 0.28;
            final bottomY = h * 0.72;
            final rail = _SplitBranchLayout.pathRailW;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: rail,
                  child: CustomPaint(
                    painter: SplitPathPainter(
                      color: accent,
                      kind: SplitPathKind.fork,
                      topY: topY,
                      bottomY: bottomY,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: rail,
                  child: CustomPaint(
                    painter: SplitPathPainter(
                      color: accent,
                      kind: SplitPathKind.merge,
                      topY: topY,
                      bottomY: bottomY,
                    ),
                  ),
                ),
                Positioned(
                  left: rail,
                  right: rail,
                  top: topY -
                      _SplitBranchLayout.knobCenterFromRowTop(soloAbove: true),
                  child: branchRow(context, 0),
                ),
                Positioned(
                  left: rail,
                  right: rail,
                  top: bottomY -
                      _SplitBranchLayout.knobCenterFromRowTop(soloAbove: false),
                  child: branchRow(context, 1),
                ),
              ],
            );
          },
        ),
      );
}
