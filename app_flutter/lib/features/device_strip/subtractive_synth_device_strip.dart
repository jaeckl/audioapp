import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'subtractive_synth_device_panel.dart';

class SubtractiveSynthDeviceStrip extends StatelessWidget {
  const SubtractiveSynthDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.onTabChanged,
    this.onOpenFullscreen,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final SubtractiveSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final SubtractiveDeviceTab? selectedTab;
  final ValueChanged<SubtractiveDeviceTab>? onTabChanged;
  final VoidCallback? onOpenFullscreen;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return SubtractiveSynthDevicePanel(
      device: device,
      onParameterChanged: onParameterChanged,
      density: SubtractivePanelDensity.strip,
      embeddedInCard: true,
      selectedTab: selectedTab,
      onTabChanged: onTabChanged,
      onOpenFullscreen: onOpenFullscreen,
      showExpandControl: onOpenFullscreen != null,
      modulatedParams: modulatedParams,
            automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
    );
  }
}
