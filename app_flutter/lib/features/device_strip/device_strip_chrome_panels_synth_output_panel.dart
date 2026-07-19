part of 'device_strip_chrome_panels.dart';

class SynthOutputPanel extends StatelessWidget {
  const SynthOutputPanel({
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
    this.audioFxExpanded = false,
    this.noteFxExpanded = false,
    this.onToggleAudioFx,
    this.onToggleNoteFx,
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
  final bool audioFxExpanded;
  final bool noteFxExpanded;
  final VoidCallback? onToggleAudioFx;
  final VoidCallback? onToggleNoteFx;

  @override
  Widget build(BuildContext context) {
    return _ChromeOutputShell(
      width: DeviceStripMetrics.synthOutputPanelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: double.infinity,
            child: Text(
              'OUT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9A9AA8),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FxToggleButton(
            label: 'Note FX',
            active: noteFxExpanded,
            accentColor: const Color(0xFFF9FF00),
            onPressed: onToggleNoteFx,
          ),
          const SizedBox(height: 10),
          _FxToggleButton(
            label: 'FX',
            active: audioFxExpanded,
            accentColor: const Color(0xFF00FF33),
            onPressed: onToggleAudioFx,
          ),
          const Spacer(),
          deviceAutomationKnob(
            label: 'Pan',
            value: device.pan.clamp(0, 1),
            size: knobSize,
            displayValue: StereoGainPanPanel.formatPan(device.pan),
            onChanged: (value) => onParameterChanged('pan', value),
            paramId: 'pan',
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
