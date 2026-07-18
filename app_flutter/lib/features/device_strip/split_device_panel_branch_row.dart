part of 'split_device_panel.dart';

/// Layout constants shared with [SplitDevicePanel] so path endpoints track knobs.
abstract final class _SplitBranchLayout {
  static const double knobSize = DeviceKnobSizes.compact;
  static const double dialHostW = knobSize + 8;
  static const double dialHostH = knobSize + 4;
  static const double soloSize = 22;
  static const double soloGap = 4;
  static const double pathRailW = 20;
  static const double toggleGap = 8;
  static const double vuW = 10;
  static const double vuGap = 6;

  /// Distance from top of branch controls column to gain-knob visual center.
  static double knobCenterFromRowTop({required bool soloAbove}) =>
      soloAbove ? soloSize + soloGap + dialHostH / 2 : dialHostH / 2;
}

extension SplitDevicePanelBranchRow on SplitDevicePanel {
  String _branchLabel(int branchIndex) {
    if (device.isMidSide) return branchIndex == 0 ? 'MID' : 'SIDE';
    return branchIndex == 0 ? 'L' : 'R';
  }

  void _setExclusiveSolo(int branchIndex, bool enable) {
    final soloParam = branchIndex == 0 ? 'branch0Solo' : 'branch1Solo';
    onChanged(soloParam, enable ? 1 : 0);
  }

  Widget branchRow(BuildContext context, int branchIndex) {
    final isBranch0 = branchIndex == 0;
    final gain = isBranch0 ? device.branch0Gain : device.branch1Gain;
    final solo = isBranch0 ? device.branch0Solo : device.branch1Solo;
    final expanded = isBranch0 ? branch0Expanded : branch1Expanded;
    final level =
        isBranch0 ? (liveMeter?.leftLevel ?? 0) : (liveMeter?.rightLevel ?? 0);
    final gainParamId = isBranch0 ? 'branch0Gain' : 'branch1Gain';

    final knob = deviceAutomationKnob(
      label: 'Gain',
      value: (gain / 2).clamp(0.0, 1.0),
      displayValue: '${(gain * 100).round()}%',
      onChanged: (v) => onChanged(gainParamId, v * 2),
      paramId: gainParamId,
      deviceId: device.id,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      lfos: lfos,
      modEdges: modEdges,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
      accentColor: accent,
      size: _SplitBranchLayout.knobSize,
    );

    final vu = SizedBox(
      width: _SplitBranchLayout.vuW,
      height: _SplitBranchLayout.dialHostH,
      child: DeviceVuMeter(active: level > 0.01 || solo, level: level),
    );

    final soloChip = SizedBox(
      width: _SplitBranchLayout.dialHostW,
      child: Center(
        child: _SoloChip(
          active: solo,
          accent: accent,
          onTap: () => _setExclusiveSolo(branchIndex, !solo),
        ),
      ),
    );

    final knobCenterY =
        _SplitBranchLayout.knobCenterFromRowTop(soloAbove: isBranch0);
    final toggleTop = (knobCenterY - SplitBranchToggleButton.height / 2)
        .clamp(0.0, double.infinity);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: toggleTop),
          child: SplitBranchToggleButton(
            label: _branchLabel(branchIndex),
            active: expanded,
            accentColor: accent,
            onPressed: () => onToggleBranch(branchIndex),
          ),
        ),
        const SizedBox(width: _SplitBranchLayout.toggleGap),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBranch0) ...[
              soloChip,
              const SizedBox(height: _SplitBranchLayout.soloGap),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                knob,
                const SizedBox(width: _SplitBranchLayout.vuGap),
                vu,
              ],
            ),
            if (!isBranch0) ...[
              const SizedBox(height: _SplitBranchLayout.soloGap),
              soloChip,
            ],
          ],
        ),
      ],
    );
  }
}

/// Small square solo toggle for one split branch.
class _SoloChip extends StatelessWidget {
  const _SoloChip({
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: _SplitBranchLayout.soloSize,
          height: _SplitBranchLayout.soloSize,
          decoration: BoxDecoration(
            color: active ? accent : const Color(0xFF222229),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: active ? accent : const Color(0xFF3A3A46),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: TextStyle(
              color: active ? const Color(0xFF14141C) : const Color(0xFF9A9AA8),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
}
