import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'kick_generator_device_panel.dart';

class KickGeneratorDeviceStrip extends StatelessWidget {
  const KickGeneratorDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.onTabChanged,
    this.modulatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final DeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final KickDeviceTab? selectedTab;
  final ValueChanged<KickDeviceTab>? onTabChanged;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return KickGeneratorDevicePanel(
      device: device,
      onParameterChanged: onParameterChanged,
      embeddedInCard: true,
      selectedTab: selectedTab,
      onTabChanged: onTabChanged,
      modulatedParams: modulatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
    );
  }
}
