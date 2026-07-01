import '../../bridge/project_snapshot.dart';

/// How an LFO maps its output when driving a modulated control.
enum ModulatorPolarity {
  bipolar,
  unipolar,
}

extension ModulatorPolarityCodec on ModulatorPolarity {
  int get wireValue => switch (this) {
        ModulatorPolarity.bipolar => 0,
        ModulatorPolarity.unipolar => 1,
      };

  static ModulatorPolarity fromWire(int value) => switch (value.clamp(0, 2)) {
        0 => ModulatorPolarity.bipolar,
        1 || 2 => ModulatorPolarity.unipolar,
        _ => ModulatorPolarity.bipolar,
      };

  static const labels = ['Bipolar', 'Unipolar'];
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
      if (lfo.type == 'envelope') {
        return ModulatorPolarity.unipolar;
      }
      return ModulatorPolarityCodec.fromWire(lfo.polarity);
    }
  }
  return ModulatorPolarity.bipolar;
}

/// Knob arc endpoints for a stored modulation amount at [value] (0..1).
({double low, double high}) modulationKnobRange({
  required ModulatorPolarity polarity,
  required double value,
  required double amount,
}) {
  final v = value.clamp(0.0, 1.0);
  final a = amount.clamp(-1.0, 1.0);
  return switch (polarity) {
    ModulatorPolarity.bipolar => (
        low: (v - a.abs()).clamp(0.0, 1.0),
        high: (v + a.abs()).clamp(0.0, 1.0),
      ),
    ModulatorPolarity.unipolar => (
        low: (v + a).clamp(0.0, 1.0) < v ? (v + a).clamp(0.0, 1.0) : v,
        high: (v + a).clamp(0.0, 1.0) > v ? (v + a).clamp(0.0, 1.0) : v,
      ),
  };
}

/// Display depth (0..1) for the vertical modulation bar inside a spinner.
double modulationBarDepth({
  required ModulatorPolarity polarity,
  required double amount,
}) {
  final a = amount.clamp(-1.0, 1.0);
  return a.abs();
}

/// Visual direction of a one-sided modulation range: -1 below, +1 above.
int modulationDisplayDirection({
  required ModulatorPolarity polarity,
  required double amount,
}) {
  if (polarity == ModulatorPolarity.bipolar || amount == 0) return 0;
  final amountDirection = amount > 0 ? 1 : -1;
  return amountDirection;
}
