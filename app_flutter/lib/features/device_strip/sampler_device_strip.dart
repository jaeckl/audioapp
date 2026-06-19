import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'sampler_device_panel.dart';

/// Compact sampler panel in the arrangement device strip.
class SamplerDeviceStrip extends StatelessWidget {
  const SamplerDeviceStrip({
    super.key,
    required this.device,
    required this.sample,
    required this.onParameterChanged,
    this.onTabChanged,
    this.onCollapse,
    this.embeddedInCard = true,
    this.selectedTab,
    this.bpm = 120,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final void Function(String parameterId, double value) onParameterChanged;
  final ValueChanged<SamplerDeviceTab>? onTabChanged;
  final VoidCallback? onCollapse;
  final bool embeddedInCard;
  final SamplerDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final int bpm;

  @override
  Widget build(BuildContext context) {
    return SamplerDevicePanel(
      device: device,
      sample: sample,
      bpm: bpm,
      onParameterChanged: onParameterChanged,
      embeddedInCard: embeddedInCard,
      onTabChanged: onTabChanged,
      onCollapse: onCollapse,
      selectedTab: selectedTab,
      density: SamplerPanelDensity.strip,
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
