import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'wavetable_synth_device_panel.dart';

class WavetableSynthDeviceStrip extends StatelessWidget {
  const WavetableSynthDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.onTabChanged,
    this.onOpenFullscreen,
    this.onOpenWavetableLibrary,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final WavetableSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final WavetableSynthDeviceTab? selectedTab;
  final ValueChanged<WavetableSynthDeviceTab>? onTabChanged;
  final VoidCallback? onOpenFullscreen;
  final VoidCallback? onOpenWavetableLibrary;
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
    return WavetableSynthDevicePanel(
      device: device,
      onParameterChanged: onParameterChanged,
      density: WavetablePanelDensity.strip,
      embeddedInCard: true,
      selectedTab: selectedTab,
      onTabChanged: onTabChanged,
      onOpenFullscreen: onOpenFullscreen,
      showExpandControl: onOpenFullscreen != null,
      onOpenWavetableLibrary: onOpenWavetableLibrary,
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
