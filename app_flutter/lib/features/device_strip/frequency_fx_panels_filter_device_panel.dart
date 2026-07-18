part of 'frequency_fx_panels.dart';

class FilterDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['filter'];
  const FilterDevicePanel({
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

  static const accent = Color(0xFF5BC0EB);
  static const containerTabs = <DeviceTabSpec>[];

  /// Filter device — compact dynamics-FX-sized card.
  static const double designWidth = 216;

  final FilterDeviceSnapshot device;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final cutoffNorm = device.ffxCutoff.clamp(0.0, 1.0);
    final resNorm = device.ffxResonance.clamp(0.0, 1.0);
    final modeNorm = device.ffxFilterMode.clamp(0.0, 1.0);
    final cutoffHz = _normalizedToFrequency(cutoffNorm);
    final q = _normalizedToQ(resNorm);
    // 4 modes quantised onto [0,1] at 0.125 / 0.375 / 0.625 / 0.875.
    final modeIndex = (modeNorm * 4.0).round().clamp(0, 3);
    return FilterSectionLayout(
      preview: EffectiveParameterValuesBuilder(
        fallbackValues: {
          'ffxCutoff': cutoffNorm,
          'ffxResonance': resNorm,
          'ffxFilterMode': modeNorm,
        },
        activeParameterIds: automatedParams,
        builder: (context, values) => FilterPreview(
          cutoffHz: _normalizedToFrequency(values['ffxCutoff']!),
          q: _normalizedToQ(values['ffxResonance']!),
          mode: FilterPreviewMode
              .values[(values['ffxFilterMode']! * 4).round().clamp(0, 3)],
          accent: accent,
        ),
      ),
      modeSelector: FilterModeSelector(
        selectedIndex: modeIndex,
        accentColor: accent,
        modulated: modulatedParams.contains('ffxFilterMode'),
        automated: automatedParams.contains('ffxFilterMode'),
        parameterId: 'ffxFilterMode',
        onSelected: (index) => onParameterChanged(
          'ffxFilterMode',
          FilterFxModeNorm.values[index],
        ),
      ),
      controls: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _knob(
              label: 'Cutoff',
              value: cutoffNorm,
              paramId: 'ffxCutoff',
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
              displayValue: _formatHz(cutoffHz),
            ),
            const SizedBox(width: DeviceStripMetrics.dynamicsFxKnobGap),
            _knob(
              label: 'Resonance',
              value: resNorm,
              paramId: 'ffxResonance',
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
              displayValue: _formatQ(q),
            ),
          ],
        ),
      ),
    );
  }
}
