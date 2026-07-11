part of 'subtractive_synth_presets.dart';

class SubtractivePresetLfo {
  const SubtractivePresetLfo({
    this.waveform = 0,
    this.rate = 1.0,
    this.syncDivision = 3,
    this.phase = 0.0,
    this.polarity = 0,
  });

  final int waveform;
  final double rate;
  final int syncDivision;
  final double phase;
  final int polarity;

  Map<String, dynamic> toJson() => {
        'waveform': waveform,
        'rate': rate,
        'syncDivision': syncDivision,
        'phase': phase,
        'polarity': polarity,
      };
}
