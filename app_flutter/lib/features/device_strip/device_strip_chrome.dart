import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../bridge/device_capabilities.dart';
import '../../devices/device_repository.dart';
import 'device_strip_chrome_panels.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'stereo_gain_pan_panel.dart';

part 'device_strip_chrome_device_strip_chrome_bindings.dart';
/// Shared modulation/automation hooks passed into strip chrome panels.
/// Per-device input/output strip chrome registry (ADR-0008).
abstract final class DeviceStripChrome {
  static const _drumTypes = {
    'kick_generator',
    'snare_generator',
    'clap_generator',
    'hihat_generator',
    'ride_generator',
    'tom_generator',
    'rimshot_generator',
    'crash_generator',
  };
  static const _fxOutputTypes = {
    'delay',
    'reverb',
    'chorus',
    'phaser',
    'bitcrusher',
    'distortion',
    'tremolo',
    'stutter_fx',
  };
  static const _emptyOutputTypes = {
    'oscilloscope',
    'spectrum_analyzer',
    'loudness_meter',
    'stereo_imager',
    'device_chain',
    'lr_split',
    'ms_split',
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
      lfos: bindings.lfos,
      modEdges: bindings.modEdges,
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
    if (_emptyOutputTypes.contains(deviceType)) {
      return EmptyChromeOutputPanel(
        width: outputWidth(deviceType),
      );
    }
    if (deviceType == 'audio_receiver' ||
        deviceType == 'midi_receiver' ||
        deviceType == 'midi_delay') {
      return RoutingOutputPanel(accentColor: bindings.accentColor);
    }
    if (_drumTypes.contains(deviceType)) {
      return DrumMonoOutputPanel(
        device: bindings.device,
        accentColor: bindings.accentColor,
        onParameterChanged: bindings.onParameterChanged,
        modulatedParams: bindings.modulatedParams,
        automatedParams: bindings.automatedParams,
        modulationAmounts: bindings.modulationAmounts,
        lfos: bindings.lfos,
        modEdges: bindings.modEdges,
        connectModeLfoId: bindings.connectModeLfoId,
        onModulationAssign: bindings.onModulationAssign,
        automationLinkActive: bindings.automationLinkActive,
        onAutomationLinkTap: bindings.onAutomationLinkTap,
        onAutomateParameter: bindings.onAutomateParameter,
      );
    }
    if ((deviceDefinitionRepository.find(deviceType)?.layout.inputPanelWidth ??
            0) >
        0) {
      return DynamicsOutputPanel(
        device: bindings.device,
        accentColor: bindings.accentColor,
        onParameterChanged: bindings.onParameterChanged,
        gainReductionDb: bindings.gainReductionDb,
        modulatedParams: bindings.modulatedParams,
        automatedParams: bindings.automatedParams,
        modulationAmounts: bindings.modulationAmounts,
        lfos: bindings.lfos,
        modEdges: bindings.modEdges,
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
        lfos: bindings.lfos,
        modEdges: bindings.modEdges,
        connectModeLfoId: bindings.connectModeLfoId,
        onModulationAssign: bindings.onModulationAssign,
        automationLinkActive: bindings.automationLinkActive,
        onAutomationLinkTap: bindings.onAutomationLinkTap,
        onAutomateParameter: bindings.onAutomateParameter,
      );
    }
    if (DeviceCapabilities.virtualStripHosts.contains(deviceType)) {
      return SynthOutputPanel(
        device: bindings.device,
        accentColor: bindings.accentColor,
        onParameterChanged: bindings.onParameterChanged,
        modulatedParams: bindings.modulatedParams,
        automatedParams: bindings.automatedParams,
        modulationAmounts: bindings.modulationAmounts,
        lfos: bindings.lfos,
        modEdges: bindings.modEdges,
        connectModeLfoId: bindings.connectModeLfoId,
        onModulationAssign: bindings.onModulationAssign,
        automationLinkActive: bindings.automationLinkActive,
        onAutomationLinkTap: bindings.onAutomationLinkTap,
        onAutomateParameter: bindings.onAutomateParameter,
        audioFxExpanded: bindings.audioFxExpanded,
        noteFxExpanded: bindings.noteFxExpanded,
        onToggleAudioFx: bindings.onToggleAudioFx,
        onToggleNoteFx: bindings.onToggleNoteFx,
      );
    }
    return StereoGainPanPanel(
      device: bindings.device,
      accentColor: bindings.accentColor,
      onParameterChanged: bindings.onParameterChanged,
      modulatedParams: bindings.modulatedParams,
      automatedParams: bindings.automatedParams,
      modulationAmounts: bindings.modulationAmounts,
      lfos: bindings.lfos,
      modEdges: bindings.modEdges,
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
