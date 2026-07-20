part of 'frequency_fx_panels.dart';

class FourBandEqDevicePanel extends StatefulWidget {
  static const registeredDeviceTypes = ['four_band_eq'];
  const FourBandEqDevicePanel({
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

  static const accent = Color(0xFF78C091);
  static const containerTabs = <DeviceTabSpec>[];

  /// EQ archetype — full-bleed curve + band plate (not Phaser rails).
  static const double designWidth = 280;

  /// ~Butterworth 0.71 → (0.71 - 0.1) / 19.9.
  static const double defaultQNorm = 0.03;

  static const bandColors = <Color>[
    Color(0xFF5BC0EB), // low shelf
    Color(0xFF78C091), // low mid
    Color(0xFFE8A54B), // high mid
    Color(0xFFE85D4B), // high shelf
  ];

  final FourBandEqDeviceSnapshot device;
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
  State<FourBandEqDevicePanel> createState() => _FourBandEqDevicePanelState();
}

class _FourBandEqDevicePanelState extends State<FourBandEqDevicePanel> {
  /// 0..3 — LS / LM / HM / HS
  int _selectedBand = 0;

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final bands = _buildPreviewBands(device);
    final bandIndex = _selectedBand + 1;
    final (freqNorm, gainNorm, qNorm) = _readBandTriplet(device, bandIndex);
    final freqId = 'ffxBand${bandIndex}Freq';
    final gainId = 'ffxBand${bandIndex}Gain';
    final qId = 'ffxBand${bandIndex}Q';
    final bandAccent = FourBandEqDevicePanel.bandColors[_selectedBand];

    return FilterSectionLayout(
      modeSelector: _FourBandEqBandSelect(
        selectedIndex: _selectedBand,
        onSelected: (i) => setState(() => _selectedBand = i),
      ),
      preview: FourBandEqPreview(
        bands: bands,
        accent: FourBandEqDevicePanel.accent,
        selectedBandIndex: _selectedBand,
        bandColors: FourBandEqDevicePanel.bandColors,
        onBandSelected: (i) => setState(() => _selectedBand = i),
        onBandEdited: (i, freqNorm, gainNorm) {
          final n = i + 1;
          widget.onParameterChanged('ffxBand${n}Freq', freqNorm);
          widget.onParameterChanged('ffxBand${n}Gain', gainNorm);
        },
      ),
      controls: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _knob(
            label: 'FREQ',
            value: freqNorm,
            paramId: freqId,
            accent: bandAccent,
            onParameterChanged: widget.onParameterChanged,
            modulatedParams: widget.modulatedParams,
            automatedParams: widget.automatedParams,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId,
            onModulationAssign: widget.onModulationAssign,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationLinkTap,
            onAutomateParameter: widget.onAutomateParameter,
            displayValue: _formatHz(_normalizedToFrequency(freqNorm)),
          ),
          _knob(
            label: 'GAIN',
            value: gainNorm,
            paramId: gainId,
            accent: bandAccent,
            onParameterChanged: widget.onParameterChanged,
            modulatedParams: widget.modulatedParams,
            automatedParams: widget.automatedParams,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId,
            onModulationAssign: widget.onModulationAssign,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationLinkTap,
            onAutomateParameter: widget.onAutomateParameter,
            displayValue: _formatDb(_normalizedToDb(gainNorm)),
          ),
          _knob(
            label: 'Q',
            value: qNorm,
            paramId: qId,
            accent: bandAccent,
            onParameterChanged: widget.onParameterChanged,
            modulatedParams: widget.modulatedParams,
            automatedParams: widget.automatedParams,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId,
            onModulationAssign: widget.onModulationAssign,
            automationLinkActive: widget.automationLinkActive,
            onAutomationLinkTap: widget.onAutomationLinkTap,
            onAutomateParameter: widget.onAutomateParameter,
            displayValue: _formatQ(_normalizedToQ(qNorm)),
          ),
        ],
      ),
    );
  }

  List<EqBand> _buildPreviewBands(FourBandEqDeviceSnapshot dev) => [
        EqBand(
          cutoffHz: _normalizedToFrequency(dev.ffxBand1Freq.clamp(0.0, 1.0)),
          gainDb: _normalizedToDb(dev.ffxBand1Gain.clamp(0.0, 1.0)),
          q: _normalizedToQ(dev.ffxBand1Q.clamp(0.0, 1.0)),
          isShelf: true,
        ),
        EqBand(
          cutoffHz: _normalizedToFrequency(dev.ffxBand2Freq.clamp(0.0, 1.0)),
          gainDb: _normalizedToDb(dev.ffxBand2Gain.clamp(0.0, 1.0)),
          q: _normalizedToQ(dev.ffxBand2Q.clamp(0.0, 1.0)),
          isShelf: false,
        ),
        EqBand(
          cutoffHz: _normalizedToFrequency(dev.ffxBand3Freq.clamp(0.0, 1.0)),
          gainDb: _normalizedToDb(dev.ffxBand3Gain.clamp(0.0, 1.0)),
          q: _normalizedToQ(dev.ffxBand3Q.clamp(0.0, 1.0)),
          isShelf: false,
        ),
        EqBand(
          cutoffHz: _normalizedToFrequency(dev.ffxBand4Freq.clamp(0.0, 1.0)),
          gainDb: _normalizedToDb(dev.ffxBand4Gain.clamp(0.0, 1.0)),
          q: _normalizedToQ(dev.ffxBand4Q.clamp(0.0, 1.0)),
          isShelf: true,
        ),
      ];
}
