part of 'device_strip_chrome_panels.dart';

/// PRE FX / POST FX toggles + Mix knob for spectral loud split.
class PrePostMixOutputPanel extends StatelessWidget {
  const PrePostMixOutputPanel({
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
    this.preFxExpanded = false,
    this.postFxExpanded = false,
    this.onTogglePreFx,
    this.onTogglePostFx,
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
  final bool preFxExpanded;
  final bool postFxExpanded;
  final VoidCallback? onTogglePreFx;
  final VoidCallback? onTogglePostFx;

  double get _mix => device is SpectralLoudSplitDeviceSnapshot
      ? (device as SpectralLoudSplitDeviceSnapshot).outputMix
      : 1.0;

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
            label: 'PRE FX',
            active: preFxExpanded,
            accentColor: accentColor,
            onPressed: onTogglePreFx,
          ),
          const SizedBox(height: 10),
          _FxToggleButton(
            label: 'POST FX',
            active: postFxExpanded,
            accentColor: accentColor,
            onPressed: onTogglePostFx,
          ),
          const Spacer(),
          deviceAutomationKnob(
            label: 'Mix',
            value: _mix.clamp(0, 1),
            size: knobSize,
            displayValue: '${(_mix * 100).round()}%',
            onChanged: (value) => onParameterChanged('outputMix', value),
            paramId: 'outputMix',
            accentColor: accentColor,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            lfos: lfos,
            modEdges: modEdges,
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
