import 'package:flutter/material.dart';

import '../../bridge/device_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

part 'utility_device_panel_body.dart';

class UtilityDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['utility'];
  static const accent = Color(0xFF94A3B8);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 200;

  const UtilityDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final UtilityDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
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
    return UtilityDevicePanelBody(
      device: device,
      onParameterChanged: onParameterChanged,
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
