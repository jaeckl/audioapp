import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'clap_generator_device_panel.dart';

class ClapGeneratorDeviceStrip extends StatelessWidget {
  const ClapGeneratorDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.onTabChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final ClapGeneratorDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final ClapDeviceTab? selectedTab;
  final ValueChanged<ClapDeviceTab>? onTabChanged;
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
    return ClapGeneratorDevicePanel(
      device: device,
      onParameterChanged: onParameterChanged,
      embeddedInCard: true,
      selectedTab: selectedTab,
      onTabChanged: onTabChanged,
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
