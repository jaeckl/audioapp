part of 'device_strip_chrome_panels.dart';

class DynamicsInputPanel extends StatelessWidget {
  const DynamicsInputPanel({
    super.key,
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.inputLevel = 0,
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
  final double inputLevel;
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
    final dynamicsDevice = device is DynamicsDeviceSnapshot
        ? device as DynamicsDeviceSnapshot
        : null;
    return Semantics(
      label: 'Dynamics input panel',
      child: _ChromeInputShell(
        child: _DynamicsSideColumn(
          label: 'IN',
          meterLevel: inputLevel.clamp(0.0, 1.0),
          accentColor: accentColor,
          bottomKnob: dynamicsDevice != null
              ? deviceAutomationKnob(
                  label: 'Trim',
                  value: dynamicsDevice.inputGain.clamp(0, 1),
                  size: knobSize,
                  displayValue:
                      StereoGainPanPanel.formatGain(dynamicsDevice.inputGain),
                  onChanged: (value) => onParameterChanged('inputGain', value),
                  paramId: 'inputGain',
                  accentColor: accentColor,
                  modulatedParams: modulatedParams,
                  automatedParams: automatedParams,
                  modulationAmounts: modulationAmounts,
                  connectModeLfoId: connectModeLfoId,
                  onModulationAssign: onModulationAssign,
                  automationLinkActive: automationLinkActive,
                  onAutomationLinkTap: onAutomationLinkTap,
                  onAutomateParameter: onAutomateParameter,
                )
              : SizedBox(height: knobSize, width: knobSize),
        ),
      ),
    );
  }
}
