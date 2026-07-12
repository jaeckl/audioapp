part of 'time_fx_panels.dart';

class ReverbFxPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['reverb'];
  const ReverbFxPanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab = ReverbViewTab.tail,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFF7B6CF6);
  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'TAIL', icon: Icons.multiline_chart),
    DeviceTabSpec(label: 'TONE', icon: Icons.equalizer),
    DeviceTabSpec(label: 'MOD', icon: Icons.waves),
  ];

  /// Version C — wide editor plus a dedicated parameter column.
  static const double designWidth = 320;

  final ReverbDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final ReverbViewTab selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    _TimeFxKnob control(
            String label, String parameter, double value, String display,
            {double knobSize = 52}) =>
        _knob(
          label: label,
          value: value,
          paramId: parameter,
          accent: accent,
          onParameterChanged: onParameterChanged,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: display,
          size: knobSize,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 6, 5, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ReverbResponseEditor(
                    device: device,
                    view: selectedTab,
                    accent: accent,
                    onParameterChanged: onParameterChanged,
                    modulatedParams: modulatedParams,
                    automatedParams: automatedParams,
                    modulationAmounts: modulationAmounts,
                    connectModeActive: connectModeLfoId != null,
                    linkModeActive: automationLinkActive,
                    onModulationAssign: onModulationAssign,
                    onAutomationLinkTap: onAutomationLinkTap,
                    onAutomateParameter: onAutomateParameter,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    control(
                      'Pre-delay',
                      'preDelay',
                      device.preDelay,
                      '${(device.preDelay * 250).round()} ms',
                    ),
                    control(
                      'Mod',
                      'modulation',
                      device.modulation,
                      '${(device.modulation * 100).round()}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: Container(
              key: const ValueKey('reverb-parameter-column'),
              decoration: BoxDecoration(
                color: const Color(0xFF050508),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  control(
                    'Decay',
                    'decay',
                    device.decay,
                    '${(.15 * math.pow(100, device.decay)).toStringAsFixed(1)} s',
                    knobSize: 48,
                  ),
                  control(
                    'Size',
                    'size',
                    device.size,
                    '${(device.size * 100).round()}%',
                    knobSize: 48,
                  ),
                  control(
                    'Diffusion',
                    'diffusion',
                    device.diffusion,
                    '${(device.diffusion * 100).round()}%',
                    knobSize: 48,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
