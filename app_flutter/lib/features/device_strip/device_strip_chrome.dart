import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_chrome_panels.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'stereo_gain_pan_panel.dart';

/// Shared modulation/automation hooks passed into strip chrome panels.
class DeviceStripChromeBindings {
  const DeviceStripChromeBindings({
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
    this.gainReductionDb = 0,
    this.inputLevel = 0,
  });

  final DeviceSnapshot device;
  final Color accentColor;
  final void Function(String parameterId, double value) onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final double gainReductionDb;
  final double inputLevel;
}

/// Per-device input/output strip chrome registry (ADR-0008).
abstract final class DeviceStripChrome {
  static const _dynamicsTypes = {'gate', 'compressor', 'expander', 'limiter'};
  static const _drumTypes = {
    'kick_generator',
    'snare_generator',
    'clap_generator',
    'cymbal_generator',
    'crash_generator',
  };
  static const _fxOutputTypes = {
    'delay', 'reverb', 'chorus', 'phaser',
    'bitcrusher', 'distortion', 'tremolo',
  };

  static bool hasInputPanel(String deviceType) =>
      DeviceStripMetrics.inputPanelWidthFor(deviceType) > 0;

  static double inputWidth(String deviceType) =>
      DeviceStripMetrics.inputPanelWidthFor(deviceType);

  static double outputWidth(String deviceType) =>
      DeviceStripMetrics.outputPanelWidthFor(deviceType);

  static Widget? inputPanel({
    required String deviceType,
    required DeviceStripChromeBindings bindings,
  }) {
    if (!hasInputPanel(deviceType)) return null;
    return DynamicsInputPanel(
      accentColor: bindings.accentColor,
      device: bindings.device,
      inputLevel: bindings.inputLevel,
      onParameterChanged: bindings.onParameterChanged,
      modulatedParams: bindings.modulatedParams,
      automatedParams: bindings.automatedParams,
      modulationAmounts: bindings.modulationAmounts,
      connectModeLfoId: bindings.connectModeLfoId,
      onModulationAssign: bindings.onModulationAssign,
      automationLinkActive: bindings.automationLinkActive,
      onAutomationLinkTap: bindings.onAutomationLinkTap,
      onAutomateParameter: bindings.onAutomateParameter,
    );
  }

  static Widget outputPanel({
    required String deviceType,
    required DeviceStripChromeBindings bindings,
  }) {
    if (_drumTypes.contains(deviceType)) {
      return DrumMonoOutputPanel(
        device: bindings.device,
        accentColor: bindings.accentColor,
        onParameterChanged: bindings.onParameterChanged,
        modulatedParams: bindings.modulatedParams,
        automatedParams: bindings.automatedParams,
        modulationAmounts: bindings.modulationAmounts,
        connectModeLfoId: bindings.connectModeLfoId,
        onModulationAssign: bindings.onModulationAssign,
        automationLinkActive: bindings.automationLinkActive,
        onAutomationLinkTap: bindings.onAutomationLinkTap,
        onAutomateParameter: bindings.onAutomateParameter,
      );
    }
    if (_dynamicsTypes.contains(deviceType)) {
      return DynamicsOutputPanel(
        device: bindings.device,
        accentColor: bindings.accentColor,
        onParameterChanged: bindings.onParameterChanged,
        gainReductionDb: bindings.gainReductionDb,
        modulatedParams: bindings.modulatedParams,
        automatedParams: bindings.automatedParams,
        modulationAmounts: bindings.modulationAmounts,
        connectModeLfoId: bindings.connectModeLfoId,
        onModulationAssign: bindings.onModulationAssign,
        automationLinkActive: bindings.automationLinkActive,
        onAutomationLinkTap: bindings.onAutomationLinkTap,
        onAutomateParameter: bindings.onAutomateParameter,
      );
    }
    if (_fxOutputTypes.contains(deviceType)) {
      return FxOutputPanel(
        device: bindings.device,
        accentColor: bindings.accentColor,
        onParameterChanged: bindings.onParameterChanged,
        modulatedParams: bindings.modulatedParams,
        automatedParams: bindings.automatedParams,
        modulationAmounts: bindings.modulationAmounts,
        connectModeLfoId: bindings.connectModeLfoId,
        onModulationAssign: bindings.onModulationAssign,
        automationLinkActive: bindings.automationLinkActive,
        onAutomationLinkTap: bindings.onAutomationLinkTap,
        onAutomateParameter: bindings.onAutomateParameter,
      );
    }
    return StereoGainPanPanel(
      device: bindings.device,
      accentColor: bindings.accentColor,
      onParameterChanged: bindings.onParameterChanged,
      modulatedParams: bindings.modulatedParams,
        automatedParams: bindings.automatedParams,
      modulationAmounts: bindings.modulationAmounts,
      connectModeLfoId: bindings.connectModeLfoId,
      onModulationAssign: bindings.onModulationAssign,
      automationLinkActive: bindings.automationLinkActive,
      onAutomationLinkTap: bindings.onAutomationLinkTap,
      onAutomateParameter: bindings.onAutomateParameter,
    );
  }

  static Color accentFor(String deviceType) =>
      DeviceStripTheme.accentForDeviceType(deviceType);
}
