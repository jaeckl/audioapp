part of 'frequency_fx_panels.dart';

class FourBandEqDevicePanel extends StatelessWidget {
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

  /// 4-band EQ — compact card.
  static const double designWidth = 216;

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
  Widget build(BuildContext context) {
    final previewBands = _buildPreviewBands(device);
    return _freqFxSinglePage(
      preview: FourBandEqPreview(bands: previewBands, accent: accent),
      rows: [
        _buildBandColumnsGrid(context, device),
      ],
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

  /// Renders the 4 EQ bands as 4 columns side-by-side. Each column has a
  /// header label and 3 stacked `ValueDragBox`es (FREQ / GAIN / Q) — the
  /// same compact shape as the Phase-Mod synth `Ratio` chip.
  Widget _buildBandColumnsGrid(
      BuildContext context, FourBandEqDeviceSnapshot dev) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var bandIndex = 1; bandIndex <= 4; bandIndex++) ...[
          if (bandIndex > 1) const SizedBox(width: _freqFxColumnGap),
          Expanded(child: _buildBandColumn(context, dev, bandIndex: bandIndex)),
        ],
      ],
    );
  }

  Widget _buildBandColumn(BuildContext context, FourBandEqDeviceSnapshot dev,
      {required int bandIndex}) {
    final (freqNorm, gainNorm, qNorm) = _readBandTriplet(dev, bandIndex);
    final freqId = 'ffxBand' '$bandIndex' 'Freq';
    final gainId = 'ffxBand' '$bandIndex' 'Gain';
    final qId = 'ffxBand' '$bandIndex' 'Q';
    final bandLabel = _bandLabel(bandIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Column header (band label)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            bandLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              height: 1.05,
            ),
          ),
        ),
        // FREQ row — drag/scroll changes freq; double-tap resets to neutral
        // (centre of the log-frequency range, i.e. ≈ 1 kHz at norm 0.5).
        ValueDragBox(
          valueNorm: freqNorm,
          // Quantised to log-spaced frequencies across the audible range.
          // The values are display strings only — the panel's `onChanged`
          // converts the index back to `[0,1]` and the engine converts to Hz.
          values: const [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
          format: (n) => _formatHz(_normalizedToFrequency(n)),
          accent: accent,
          paramId: freqId,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          onChanged: (v) => onParameterChanged(freqId, v),
          resetIndex: 5, // ~ 1 kHz
          dragPixelsPerStep: 14,
          footerLabel: 'FREQ',
        ),
        const SizedBox(height: 4),
        // GAIN row — discrete gain steps in dB. Double-tap resets to 0 dB
        // (neutral, idx 4 of the 9 steps centred on 0 dB).
        ValueDragBox(
          valueNorm: gainNorm,
          values: const [-24.0, -18.0, -12.0, -6.0, 0.0, 6.0, 12.0, 18.0, 24.0],
          // Display uses _formatDb for consistency, but values are absolute dB.
          format: (n) => _formatDb(_normalizedToDb(n)),
          accent: accent,
          paramId: gainId,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          onChanged: (v) => onParameterChanged(gainId, v),
          resetIndex: 4, // 0 dB
          dragPixelsPerStep: 14,
          footerLabel: 'GAIN',
        ),
        const SizedBox(height: 4),
        // Q row — discrete Q values from 0.1 to 20.0.
        ValueDragBox(
          valueNorm: qNorm,
          values: const [
            0.10,
            0.25,
            0.50,
            0.71,
            1.00,
            1.41,
            2.00,
            4.00,
            8.00,
            20.00
          ],
          // Display uses _formatQ for consistency, but values are absolute Q.
          format: (n) => _formatQ(_normalizedToQ(n)),
          accent: accent,
          paramId: qId,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          onChanged: (v) => onParameterChanged(qId, v),
          resetIndex: 3, // Q ≈ 0.71 (Butterworth)
          dragPixelsPerStep: 14,
          footerLabel: 'Q',
        ),
      ],
    );
  }

  static String _bandLabel(int bandIndex) {
    switch (bandIndex) {
      case 1:
        return 'LOW SHELF';
      case 2:
        return 'LOW MID';
      case 3:
        return 'HIGH MID';
      case 4:
        return 'HIGH SHELF';
      default:
        return '';
    }
  }
}
