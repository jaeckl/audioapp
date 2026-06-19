import 'package:audioapp/features/device_strip/modulator_polarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('modulationBarDepth respects polarity', () {
    expect(
      modulationBarDepth(polarity: ModulatorPolarity.bipolar, amount: -0.5),
      0.5,
    );
    expect(
      modulationBarDepth(polarity: ModulatorPolarity.positive, amount: -0.5),
      0.0,
    );
    expect(
      modulationBarDepth(polarity: ModulatorPolarity.positive, amount: 0.4),
      0.4,
    );
    expect(
      modulationBarDepth(polarity: ModulatorPolarity.negative, amount: 0.5),
      0.0,
    );
    expect(
      modulationBarDepth(polarity: ModulatorPolarity.negative, amount: -0.6),
      0.6,
    );
  });
}
