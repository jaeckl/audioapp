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
  });

  final DeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final SubtractiveDeviceTab? selectedTab;
  final ValueChanged<SubtractiveDeviceTab>? onTabChanged;
  final VoidCallback? onOpenFullscreen;

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
    );
  }
}
