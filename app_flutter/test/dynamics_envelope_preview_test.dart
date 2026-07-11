import 'package:audioapp/features/device_strip/dynamics_envelope_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compressor is unity below threshold and compresses above it', () {
    final threshold = dynamicsThresholdDb(.5);
    final below = dynamicsPreviewOutputDb(
      mode: DynamicsPreviewMode.compressor,
      inputDb: threshold - 10,
      threshold: .5,
      ratio: .5,
    );
    final above = dynamicsPreviewOutputDb(
      mode: DynamicsPreviewMode.compressor,
      inputDb: threshold + 10,
      threshold: .5,
      ratio: .5,
    );
    expect(below, closeTo(threshold - 10, 1e-9));
    expect(above, lessThan(threshold + 10));
    expect(above, greaterThan(threshold));
  });

  test('expander attenuates below threshold and remains monotonic', () {
    const threshold = .5;
    var previous = double.negativeInfinity;
    for (var input = -60.0; input <= 0; input += .25) {
      final output = dynamicsPreviewOutputDb(
        mode: DynamicsPreviewMode.expander,
        inputDb: input,
        threshold: threshold,
        ratio: .6,
        range: .4,
      );
      expect(output, greaterThanOrEqualTo(previous));
      if (input < dynamicsThresholdDb(threshold)) {
        expect(output, lessThanOrEqualTo(input));
      }
      previous = output;
    }
  });

  test('gate applies its floor only below threshold', () {
    final threshold = dynamicsThresholdDb(.4);
    final closed = dynamicsPreviewOutputDb(
      mode: DynamicsPreviewMode.gate,
      inputDb: threshold - 1,
      threshold: .4,
      range: .5,
    );
    final open = dynamicsPreviewOutputDb(
      mode: DynamicsPreviewMode.gate,
      inputDb: threshold + 1,
      threshold: .4,
      range: .5,
    );
    expect(closed, closeTo(threshold - 41, 1e-9));
    expect(open, closeTo(threshold + 1, 1e-9));
  });

  test('limiter never exceeds ceiling before makeup', () {
    final ceiling = dynamicsCeilingDb(.75);
    for (var input = -60.0; input <= 0; input += .25) {
      final output = dynamicsPreviewOutputDb(
        mode: DynamicsPreviewMode.limiter,
        inputDb: input,
        threshold: .75,
        ceiling: .75,
        knee: .2,
        drive: .5,
      );
      expect(output, lessThanOrEqualTo(ceiling + 1e-9));
    }
  });

  testWidgets('all transfer previews paint without exceptions', (tester) async {
    for (final mode in DynamicsPreviewMode.values) {
      await tester.pumpWidget(MaterialApp(
        home: SizedBox(
          width: 240,
          height: 120,
          child: DynamicsEnvelopePreview(
            threshold: .5,
            ratio: .5,
            knee: .25,
            range: .25,
            drive: .2,
            ceiling: .8,
            mode: mode,
            accent: Colors.orange,
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
