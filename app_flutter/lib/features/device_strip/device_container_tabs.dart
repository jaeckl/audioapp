import 'package:flutter/material.dart';

import 'device_tab_bar.dart';
import 'oscillator_device_panel.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';

/// Device types register container header tabs here (icon + label).
abstract final class DeviceContainerTabs {
  static List<DeviceTabSpec> forDeviceType(String deviceType) {
    return switch (deviceType) {
      'simple_sampler' => SamplerDevicePanel.containerTabs,
      'simple_oscillator' => OscillatorDevicePanel.containerTabs,
      'subtractive_synth' => SubtractiveSynthDevicePanel.containerTabs,
      _ => const <DeviceTabSpec>[],
    };
  }
}
