part of 'modulator_polarity.dart';

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
