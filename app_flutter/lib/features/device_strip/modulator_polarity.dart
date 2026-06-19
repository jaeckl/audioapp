import '../../bridge/project_snapshot.dart';

/// How an LFO maps its output when driving a modulated control.
enum ModulatorPolarity {
  bipolar,
  positive,
  negative,
}

extension ModulatorPolarityCodec on ModulatorPolarity {
  int get wireValue => switch (this) {
        ModulatorPolarity.bipolar => 0,
        ModulatorPolarity.positive => 1,
        ModulatorPolarity.negative => 2,
      };

  static ModulatorPolarity fromWire(int value) => switch (value.clamp(0, 2)) {
        0 => ModulatorPolarity.bipolar,
        1 => ModulatorPolarity.positive,
        2 => ModulatorPolarity.negative,
        _ => ModulatorPolarity.bipolar,
      };

  static const labels = ['Bipolar', 'Positive', 'Negative'];
  String get label => labels[wireValue];
}

ModulatorPolarity modulatorPolarityForParam({
  required String paramId,
  required String deviceId,
  required List<ModulationEdgeSnapshot> modEdges,
  required List<LfoSnapshot> lfos,
  int? connectModeLfoId,
}) {
  int? lfoId = connectModeLfoId;
  if (lfoId == null) {
    for (final edge in modEdges) {
      if (edge.deviceId == deviceId && edge.paramId == paramId) {
        lfoId = edge.lfoId;
        break;
      }
    }
  }
  if (lfoId == null) return ModulatorPolarity.bipolar;
  for (final lfo in lfos) {
    if (lfo.id == lfoId) {
      return ModulatorPolarityCodec.fromWire(lfo.polarity);
    }
  }
  return ModulatorPolarity.bipolar;
}

/// Display depth (0..1) for the vertical modulation bar inside a spinner.
double modulationBarDepth({
  required ModulatorPolarity polarity,
  required double amount,
}) {
  final a = amount.clamp(-1.0, 1.0);
  return switch (polarity) {
    ModulatorPolarity.bipolar => a.abs(),
    ModulatorPolarity.positive => a.clamp(0.0, 1.0),
    ModulatorPolarity.negative => (-a).clamp(0.0, 1.0),
  };
}
