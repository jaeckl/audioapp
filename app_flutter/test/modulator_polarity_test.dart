import 'package:audioapp/features/device_strip/modulator_polarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('modulationBarDepth respects polarity', () {
    expect(
      modulationBarDepth(polarity: ModulatorPolarity.bipolar, amount: -0.5),
      0.5,
    );
    expect(
      modulationBarDepth(polarity: ModulatorPolarity.unipolar, amount: -0.5),
      0.5,
    );
    expect(
      modulationBarDepth(polarity: ModulatorPolarity.unipolar, amount: 0.4),
      0.4,
    );
  });

  test('modulationKnobRange is one-sided for unipolar sources', () {
    final range = modulationKnobRange(
      polarity: ModulatorPolarity.unipolar,
      value: 0.2,
      amount: 0.5,
    );
    expect(range.low, 0.2);
    expect(range.high, 0.7);

    final negative = modulationKnobRange(
      polarity: ModulatorPolarity.unipolar,
      value: 0.6,
      amount: -0.25,
    );
    expect(negative.low, 0.35);
    expect(negative.high, 0.6);
  });

  test('modulationKnobRange expands both ways for bipolar', () {
    final range = modulationKnobRange(
      polarity: ModulatorPolarity.bipolar,
      value: 0.5,
      amount: -0.4,
    );
    expect(range.low, closeTo(0.1, 0.001));
    expect(range.high, closeTo(0.9, 0.001));
  });

  test('unipolar spinner depth preserves either amount sign', () {
    expect(
      modulationBarDepth(
        polarity: ModulatorPolarity.unipolar,
        amount: -0.4,
      ),
      0.4,
    );
  });
}
