part of 'device_strip_chrome_panels.dart';

class DrumMonoOutputPanel extends StatelessWidget {
  const DrumMonoOutputPanel({
    super.key,
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.knobSize = DeviceKnobSizes.compact,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
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
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static String? velocityParamIdFor(String deviceType) => switch (deviceType) {
        'kick_generator' => 'kickVelocity',
        'snare_generator' => 'snareVelocity',
        'clap_generator' => 'clapVelocity',
        'hihat_generator' => 'hihatVelocity',
        'ride_generator' => 'rideVelocity',
        'tom_generator' => 'tomVelocity',
        'rimshot_generator' => 'rimshotVelocity',
        'crash_generator' => 'crashVelocity',
        _ => null,
      };

  static double velocityFor(DeviceSnapshot device) => switch (device) {
        KickGeneratorDeviceSnapshot() => device.kickVelocity,
        SnareGeneratorDeviceSnapshot() => device.snareVelocity,
        ClapGeneratorDeviceSnapshot() => device.clapVelocity,
        DedicatedPercussionDeviceSnapshot() => device.value(
            velocityParamIdFor(device.type) ?? '', 1.0),
        CrashGeneratorDeviceSnapshot() => device.crashVelocity,
        _ => 1.0,
      };

  @override
  Widget build(BuildContext context) {
    final velocityParamId = velocityParamIdFor(device.type);
    final velocity = velocityFor(device);

    return _ChromeOutputShell(
      width: DeviceStripMetrics.drumMonoOutputPanelWidth,
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
              automatedParams: automatedParams,
              modulationAmounts: modulationAmounts,
              lfos: lfos,
              modEdges: modEdges,
              deviceId: device.id,
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
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            lfos: lfos,
            modEdges: modEdges,
            deviceId: device.id,
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
