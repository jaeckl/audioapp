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
        _ => null,
      };

  static double velocityFor(DeviceSnapshot device) => switch (device.type) {
        'kick_generator' => device.kickVelocity,
        'snare_generator' => device.snareVelocity,
        'clap_generator' => device.clapVelocity,
        'cymbal_generator' => device.cymbalVelocity,
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

/// Dynamics FX input column (left of card). v1: placeholder meter until bridge metering lands.
class DynamicsInputPanel extends StatelessWidget {
  const DynamicsInputPanel({
    super.key,
    required this.accentColor,
    this.inputLevel = 0,
  });

  final Color accentColor;
  final double inputLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Dynamics input panel',
      child: _ChromeInputShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'IN',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white38,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: DeviceStripTheme.cardBorder),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: inputLevel.clamp(0.05, 1.0),
                    widthFactor: 0.55,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dynamics FX output column: gain + gain-reduction readout (v1 GR placeholder).
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

  static String formatGainReduction(double db) {
    if (db <= 0.05) return '0 dB';
    return '-${db.toStringAsFixed(1)} dB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ChromeOutputShell(
      width: DeviceStripMetrics.dynamicsOutputPanelWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'GR',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white38,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 9,
            ),
          ),
          Text(
            formatGainReduction(gainReductionDb),
            style: theme.textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 8),
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

class _ChromeOutputShell extends StatelessWidget {
  const _ChromeOutputShell({
    required this.child,
    this.width = DeviceStripMetrics.stereoOutputPanelWidth,
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
    final leftRadius = Radius.circular(DeviceStripTheme.toolRailRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeviceStripTheme.toolRailBackground,
        borderRadius: BorderRadius.only(topLeft: leftRadius, bottomLeft: leftRadius),
        border: const Border(
          top: borderSide,
          left: borderSide,
          bottom: borderSide,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: child,
      ),
    );
  }
}
