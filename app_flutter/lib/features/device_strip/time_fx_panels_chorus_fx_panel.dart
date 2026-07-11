part of 'time_fx_panels.dart';

class ChorusFxPanel extends StatelessWidget {
  const ChorusFxPanel({
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

  static const accent = Color(0xFFE8A54B);
  static const containerTabs = <DeviceTabSpec>[];

  /// Chorus — compact time FX card.
  static const double designWidth = 216;

  final ChorusDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
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
    final mode = device.modeMorph.round().clamp(0, 3);
    final bank = switch (mode) {
      1 => device.ensemble,
      2 => device.dimension,
      3 => device.drift,
      _ => device.classic,
    };
    final definitions = switch (mode) {
      1 => <(String, String, String Function(double))>[
          (
            'Rate',
            'ensembleRate',
            (v) => '${(0.05 + v * 1.95).toStringAsFixed(2)} Hz'
          ),
          ('Depth', 'ensembleDepth', (v) => '${(v * 100).round()}%'),
          ('Voices', 'ensembleVoices', (v) => '${2 + (v * 2).round()}'),
          ('Spread', 'ensembleSpread', (v) => '${(v * 100).round()}%'),
          ('Drift', 'ensembleDrift', (v) => '${(v * 100).round()}%'),
          ('Tone', 'ensembleTone', (v) => _formatHz(3000 + v * 17000)),
        ],
      2 => <(String, String, String Function(double))>[
          ('Amount', 'dimensionAmount', (v) => '${(v * 100).round()}%'),
          (
            'Delay',
            'dimensionDelay',
            (v) => '${(4 + v * 20).toStringAsFixed(1)} ms'
          ),
          ('Spread', 'dimensionSpread', (v) => '${(v * 100).round()}%'),
          ('Motion', 'dimensionMotion', (v) => '${(v * 100).round()}%'),
          (
            'Low Cut',
            'dimensionLowCut',
            (v) => _formatHz((20 * math.pow(50, v)).toDouble())
          ),
          (
            'High Cut',
            'dimensionHighCut',
            (v) => _formatHz((2000 * math.pow(10, v)).toDouble())
          ),
        ],
      3 => <(String, String, String Function(double))>[
          (
            'Speed',
            'driftSpeed',
            (v) => '${(0.02 + v * 0.98).toStringAsFixed(2)} Hz'
          ),
          ('Depth', 'driftDepth', (v) => '${(v * 100).round()}%'),
          ('Wander', 'driftWander', (v) => '${(v * 100).round()}%'),
          (
            'Delay',
            'driftDelay',
            (v) => '${(3 + v * 27).toStringAsFixed(1)} ms'
          ),
          ('Stereo', 'driftStereo', (v) => '${(v * 100).round()}%'),
          ('Tone', 'driftTone', (v) => _formatHz(2500 + v * 17500)),
        ],
      _ => <(String, String, String Function(double))>[
          (
            'Rate',
            'classicRate',
            (v) => '${(0.1 + v * 4.9).toStringAsFixed(2)} Hz'
          ),
          ('Depth', 'classicDepth', (v) => '${(v * 100).round()}%'),
          (
            'Delay',
            'classicDelay',
            (v) => '${(2 + v * 18).toStringAsFixed(1)} ms'
          ),
          ('Feedback', 'classicFeedback', (v) => '${(v * 80).round()}%'),
          ('Phase', 'classicPhase', (v) => '${(v * 180).round()}°'),
          (
            'Shape',
            'classicShape',
            (v) => v < .33
                ? 'Sine'
                : v > .67
                    ? 'Triangle'
                    : 'Morph'
          ),
        ],
    };

    _TimeFxKnob control(int index) => _knob(
          label: definitions[index].$1,
          value: bank[index],
          paramId: definitions[index].$2,
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
          displayValue: definitions[index].$3(bank[index]),
        );

    return _timeFxSinglePage(
      rows: [
        _MorphModeGroup(
          labels: const ['Classic', 'Ensemble', 'Dimension', 'Drift'],
          keyPrefix: 'chorus-mode',
          value: device.modeMorph,
          accent: accent,
          modulationActive: modulatedParams.contains('modeMorph'),
          modulationAmount: modulationAmounts['modeMorph'] ?? 0,
          automationActive: automatedParams.contains('modeMorph'),
          connectModeActive: connectModeLfoId != null,
          linkModeActive: automationLinkActive,
          onChanged: (value) => onParameterChanged('modeMorph', value),
          onModulationAssign: onModulationAssign == null
              ? null
              : (amount) => onModulationAssign!('modeMorph', amount),
          onAutomationLinkTap: onAutomationLinkTap == null
              ? null
              : () => onAutomationLinkTap!('modeMorph'),
          onAutomateRequest: onAutomateParameter == null
              ? null
              : () => onAutomateParameter!('modeMorph'),
        ),
        _knobGridRow([
          control(0),
          control(1),
          control(2),
        ]),
        _knobGridRow([
          control(3),
          control(4),
          control(5),
        ]),
      ],
    );
  }
}
