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
    this.modulatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
  });

  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final void Function(String parameterId, double value) onParameterChanged;
  final ValueChanged<SamplerDeviceTab>? onTabChanged;
  final VoidCallback? onCollapse;
  final bool embeddedInCard;
  final SamplerDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, String paramLabel)? onModulationAssign;

  @override
  Widget build(BuildContext context) {
    return SamplerDevicePanel(
      device: device,
      sample: sample,
      onParameterChanged: onParameterChanged,
      embeddedInCard: embeddedInCard,
      onTabChanged: onTabChanged,
      onCollapse: onCollapse,
      selectedTab: selectedTab,
      density: SamplerPanelDensity.strip,
      modulatedParams: modulatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
    );
  }
}
