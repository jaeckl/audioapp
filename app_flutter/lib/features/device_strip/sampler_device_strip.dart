import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'sampler_device_panel.dart';

/// Compact sampler panel in the arrangement device strip.
class SamplerDeviceStrip extends StatelessWidget {
  const SamplerDeviceStrip({
    super.key,
    required this.trackName,
    required this.device,
    required this.sample,
    required this.onParameterChanged,
    required this.onOpenFullscreen,
  });

  final String trackName;
  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final void Function(String parameterId, double value) onParameterChanged;
  final VoidCallback onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    return SamplerDevicePanel(
      device: device,
      sample: sample,
      onParameterChanged: onParameterChanged,
      showExpandControl: true,
      onOpenFullscreen: onOpenFullscreen,
    );
  }
}
