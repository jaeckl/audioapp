part of 'bass_synth_presets.dart';

class BassSynthPreset {
  const BassSynthPreset({
    required this.params,
    this.lfos = const [],
    this.mods = const [],
    this.audioFx = const [],
  });

  final Map<String, double> params;
  final List<BassPresetLfo> lfos;
  final List<BassPresetMod> mods;
  final List<Map<String, dynamic>> audioFx;
}

class BassPresetLfo {
  const BassPresetLfo({
    this.waveform = 0,
    this.rate = 1.0,
    this.syncDivision = 3,
    this.phase = 0.0,
    this.polarity = 0,
    this.retrigger = 0,
  });

  final int waveform;
  final double rate;
  final int syncDivision;
  final double phase;
  final int polarity;
  final int retrigger;

  Map<String, dynamic> toJson(int id) => {
        'id': id,
        'type': 'lfo',
        'ownerDeviceId': 'factory',
        'waveform': waveform,
        'rate': rate,
        'syncDivision': syncDivision,
        'phase': phase,
        'polarity': polarity,
        'retrigger': retrigger,
        'attack': 0.1,
        'decay': 0.25,
        'sustain': 0.7,
        'release': 0.35,
        'morph': 0.0,
        'spread': 0.5,
        'analogMode': 0,
      };
}

class BassPresetMod {
  const BassPresetMod({
    required this.lfoIndex,
    required this.paramId,
    required this.amount,
  });

  final int lfoIndex;
  final String paramId;
  final double amount;
}
