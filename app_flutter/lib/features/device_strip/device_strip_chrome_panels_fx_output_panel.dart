part of 'device_strip_chrome_panels.dart';

class FxOutputPanel extends StatelessWidget {
  const FxOutputPanel({
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

  @override
  Widget build(BuildContext context) {
    final eff =
        device is EffectDeviceSnapshot ? device as EffectDeviceSnapshot : null;
    final mix = eff?.outputMix ?? 1.0;
    final width = eff?.outputWidth ?? 1.0;

    return _ChromeOutputShell(
      width: DeviceStripMetrics.dynamicsOutputPanelWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'OUT',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          deviceAutomationKnob(
            label: 'Width',
            value: width.clamp(0, 1),
            size: knobSize,
            displayValue: '${(width * 100).round()}%',
            onChanged: (value) => onParameterChanged('outputWidth', value),
            paramId: 'outputWidth',
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
          const SizedBox(height: 16),
          deviceAutomationKnob(
            label: 'Mix',
            value: mix.clamp(0, 1),
            size: knobSize,
            displayValue: '${(mix * 100).round()}%',
            onChanged: (value) => onParameterChanged('outputMix', value),
            paramId: 'outputMix',
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
      ),
    );
  }
}
