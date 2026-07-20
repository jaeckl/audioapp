part of 'device_strip_chrome_panels.dart';

class DynamicsOutputPanel extends StatelessWidget {
  const DynamicsOutputPanel({
    super.key,
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.gainReductionDb = 0,
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
    this.onToggleAudioFx,
  });

  final DeviceSnapshot device;
  final Color accentColor;
  final void Function(String parameterId, double value) onParameterChanged;
  final double gainReductionDb;
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
  final VoidCallback? onToggleAudioFx;

  /// Engine publishes gain reduction as ≤0 dB (and Gate publishes open-gain
  /// the same way when closed). Meter needs magnitude.
  static double gainReductionMeterLevel(double db) {
    const maxDb = 24.0;
    return (db.abs() / maxDb).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final column = _DynamicsSideColumn(
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
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      ),
    );
    return _ChromeOutputShell(
      width: DeviceStripMetrics.dynamicsOutputPanelWidth,
      child: onToggleAudioFx == null
          ? column
          : Column(
              children: [
                _FxToggleButton(
                  label: 'FX',
                  active: audioFxExpanded,
                  accentColor: const Color(0xFF00FF33),
                  onPressed: onToggleAudioFx,
                ),
                const SizedBox(height: 6),
                Expanded(child: column),
              ],
            ),
    );
  }
}
