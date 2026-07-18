part of 'sampler_device_panel.dart';

class _ToneTab extends StatelessWidget {
  const _ToneTab({
    required this.device,
    required this.knobSize,
    required this.editor,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeLfoId,
    required this.onModulationAssign,
    required this.automationLinkActive,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final SamplerDeviceSnapshot device;
  final double knobSize;
  final bool editor;
  final void Function(String parameterId, double value) onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const _toneCellDecoration = BoxDecoration(
    color: Color(0xFF121218),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    border: Border.fromBorderSide(BorderSide(color: Color(0x14FFFFFF))),
  );

  @override
  Widget build(BuildContext context) {
    final modeIndex = device.filterMode.clamp(0, 3);
    final maxFilterKnob =
        editor ? DeviceKnobSizes.editor : DeviceKnobSizes.strip;
    final filterKnob = maxFilterKnob * 0.76;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: DeviceSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'FILTER',
                  textAlign: TextAlign.center,
                  style: DevicePanelTheme.sectionLabel,
                ),
                const SizedBox(height: 4),
                DevicePreviewFrame(
                  height: DevicePanelTheme.previewStripHeight,
                  child: FilterPreview(
                    cutoffHz: DeviceParamFormatters.cutoffHzFromNormalized(
                      device.filterCutoff,
                    ),
                    q: DeviceParamFormatters.qFromNormalized(device.filterQ),
                    mode: _filterPreviewMode(modeIndex),
                    accent: SamplerDevicePanel.accent,
                  ),
                ),
                const SizedBox(height: 4),
                FilterModeSelector(
                  selectedIndex: modeIndex,
                  parameterId: 'filterMode',
                  automated: automatedParams.contains('filterMode'),
                  modulated: modulatedParams.contains('filterMode'),
                  accentColor: SamplerDevicePanel.accent,
                  onSelected: (index) =>
                      onParameterChanged('filterMode', index.toDouble()),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _filterKnobSlot(
                          maxKnob: filterKnob,
                          label: 'Cutoff',
                          paramId: 'filterCutoff',
                          value: device.filterCutoff,
                          displayValue: SamplerDevicePanel.formatCutoffHz(
                              device.filterCutoff),
                          onChanged: (v) =>
                              onParameterChanged('filterCutoff', v),
                        ),
                      ),
                      Expanded(
                        child: _filterKnobSlot(
                          maxKnob: filterKnob,
                          label: 'Res',
                          paramId: 'filterQ',
                          value: device.filterQ,
                          displayValue:
                              SamplerDevicePanel.formatQ(device.filterQ),
                          onChanged: (v) => onParameterChanged('filterQ', v),
                        ),
                      ),
                      Expanded(
                        child: _filterKnobSlot(
                          maxKnob: filterKnob,
                          label: 'FEG',
                          paramId: 'filterEnvAmount',
                          value: device.filterEnvAmount,
                          displayValue: SamplerDevicePanel.formatPercent(
                              device.filterEnvAmount),
                          onChanged: (v) =>
                              onParameterChanged('filterEnvAmount', v),
                          accentColor: SamplerDevicePanel.wave,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _previewCell(
                  SamplerEnvelopePreview(
                    attack: device.attack,
                    decay: device.decay,
                    sustain: device.sustain,
                    release: device.release,
                    accent: SamplerDevicePanel.accent,
                    label: 'AEG',
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                flex: 8,
                child: _toneCell(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: _buildAdsrPanel(editor),
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                flex: 3,
                child: _previewCell(
                  SamplerEnvelopePreview(
                    attack: device.filterAttack,
                    decay: device.filterDecay,
                    sustain: device.filterSustain,
                    release: device.filterRelease,
                    accent: SamplerDevicePanel.wave,
                    label: 'FEG',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  FilterPreviewMode _filterPreviewMode(int mode) {
    switch (mode) {
      case 1:
        return FilterPreviewMode.highPass;
      case 2:
        return FilterPreviewMode.bandPass;
      case 3:
        return FilterPreviewMode.notch;
      default:
        return FilterPreviewMode.lowPass;
    }
  }

  /// Amp + filter ADSR rows with shared A/D/S/R labels centered between them.
}
