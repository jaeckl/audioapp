part of 'subtractive_synth_presets.dart';

class SubtractiveSynthPreset {
  const SubtractiveSynthPreset({
    required this.params,
    this.lfos = const [],
    this.mods = const [],
  });

  final Map<String, double> params;
  final List<SubtractivePresetLfo> lfos;
  final List<SubtractivePresetMod> mods;
}
