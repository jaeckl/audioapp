import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'stereo_gain_pan_panel.dart';

/// Mono drum output rail: gain + velocity sensitivity (no pan).
class DrumMonoOutputPanel extends StatelessWidget {
  const DrumMonoOutputPanel({
    super.key,
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.knobSize = DeviceKnobSizes.compact,
    this.modulatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final DeviceSnapshot device;
  final Color accentColor;
  final void Function(String parameterId, double value) onParameterChanged;
  final double knobSize;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static String? velocityParamIdFor(String deviceType) => switch (deviceType) {
        'kick_generator' => 'kickVelocity',
        'snare_generator' => 'snareVelocity',
        'clap_generator' => 'clapVelocity',
        'cymbal_generator' => 'cymbalVelocity',
        'crash_generator' => 'crashVelocity',
        _ => null,
      };

  static double velocityFor(DeviceSnapshot device) => switch (device.type) {
        'kick_generator' => device.kickVelocity,
        'snare_generator' => device.snareVelocity,
        'clap_generator' => device.clapVelocity,
        'cymbal_generator' => device.cymbalVelocity,
        'crash_generator' => device.crashVelocity,
        _ => 1.0,
      };

  @override
  Widget build(BuildContext context) {
    final velocityParamId = velocityParamIdFor(device.type);
    final velocity = velocityFor(device);

    return _ChromeOutputShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (velocityParamId != null) ...[
            deviceAutomationKnob(
              label: 'Vel sens',
              value: velocity.clamp(0, 1),
              size: knobSize,
              displayValue: '${(velocity * 100).round()}%',
              onChanged: (value) => onParameterChanged(velocityParamId, value),
              paramId: velocityParamId,
              accentColor: accentColor,
              modulatedParams: modulatedParams,
              modulationAmounts: modulationAmounts,
              connectModeLfoId: connectModeLfoId,
              onModulationAssign: onModulationAssign,
              automationLinkActive: automationLinkActive,
              onAutomationLinkTap: onAutomationLinkTap,
              onAutomateParameter: onAutomateParameter,
            ),
            const SizedBox(height: 8),
          ],
          deviceAutomationKnob(
            label: 'Gain',
            value: device.gain.clamp(0, 1),
            size: knobSize,
            displayValue: StereoGainPanPanel.formatGain(device.gain),
            onChanged: (value) => onParameterChanged('gain', value),
            paramId: 'gain',
            accentColor: accentColor,
            modulatedParams: modulatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
          ),
        ],
      ),
    );
  }
}

/// Dynamics FX input column (left of card): input meter + trim gain.
class DynamicsInputPanel extends StatelessWidget {
  const DynamicsInputPanel({
    super.key,
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.inputLevel = 0,
    this.knobSize = DeviceKnobSizes.compact,
    this.modulatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final DeviceSnapshot device;
  final Color accentColor;
  final void Function(String parameterId, double value) onParameterChanged;
  final double inputLevel;
  final double knobSize;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dynamics input panel',
      child: _ChromeInputShell(
        child: _DynamicsSideColumn(
          label: 'IN',
          meterLevel: inputLevel.clamp(0.0, 1.0),
          accentColor: accentColor,
          bottomKnob: deviceAutomationKnob(
            label: 'Trim',
            value: device.inputGain.clamp(0, 1),
            size: knobSize,
            displayValue: StereoGainPanPanel.formatGain(device.inputGain),
            onChanged: (value) => onParameterChanged('inputGain', value),
            paramId: 'inputGain',
            accentColor: accentColor,
            modulatedParams: modulatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
          ),
        ),
      ),
    );
  }
}

/// Dynamics FX output column: gain-reduction meter + output gain.
class DynamicsOutputPanel extends StatelessWidget {
  const DynamicsOutputPanel({
    super.key,
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.gainReductionDb = 0,
    this.knobSize = DeviceKnobSizes.compact,
    this.modulatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final DeviceSnapshot device;
  final Color accentColor;
  final void Function(String parameterId, double value) onParameterChanged;
  final double gainReductionDb;
  final double knobSize;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static double gainReductionMeterLevel(double db) {
    const maxDb = 24.0;
    return (db / maxDb).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return _ChromeOutputShell(
      child: _DynamicsSideColumn(
        label: 'GR',
        meterLevel: gainReductionMeterLevel(gainReductionDb),
        accentColor: accentColor,
        bottomKnob: deviceAutomationKnob(
          label: 'Gain',
          value: device.gain.clamp(0, 1),
          size: knobSize,
          displayValue: StereoGainPanPanel.formatGain(device.gain),
          onChanged: (value) => onParameterChanged('gain', value),
          paramId: 'gain',
          accentColor: accentColor,
          modulatedParams: modulatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
        ),
      ),
    );
  }
}

class _DynamicsSideColumn extends StatelessWidget {
  const _DynamicsSideColumn({
    required this.label,
    required this.meterLevel,
    required this.accentColor,
    required this.bottomKnob,
  });

  static const double _meterWidth = 28;

  final String label;
  final double meterLevel;
  final Color accentColor;
  final Widget bottomKnob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleLevel = meterLevel <= 0.001 ? 0.0 : meterLevel.clamp(0.05, 1.0);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white38,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: SizedBox(
              width: _meterWidth,
              child: ColoredBox(
                color: Colors.black26,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: visibleLevel,
                    widthFactor: 1.0,
                    child: ColoredBox(color: accentColor.withValues(alpha: 0.65)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        bottomKnob,
      ],
    );
  }
}

class _ChromeOutputShell extends StatelessWidget {
  const _ChromeOutputShell({
    required this.child,
    this.width = DeviceStripMetrics.dynamicsOutputPanelWidth,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );
    final rightRadius = Radius.circular(DeviceStripTheme.toolRailRadius);

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DeviceStripTheme.toolRailBackground,
          borderRadius: BorderRadius.only(topRight: rightRadius, bottomRight: rightRadius),
          border: const Border(
            top: borderSide,
            bottom: borderSide,
            right: borderSide,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}

class _ChromeInputShell extends StatelessWidget {
  const _ChromeInputShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );

    return SizedBox(
      width: DeviceStripMetrics.dynamicsInputPanelWidth,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: DeviceStripTheme.toolRailBackground,
          border: Border(
            top: borderSide,
            bottom: borderSide,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}
