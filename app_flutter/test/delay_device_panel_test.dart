import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/time_fx_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DelayDeviceSnapshot _delay({
  double timeMode = 0,
  double noteCount = 1,
  double blurMode = 0,
}) =>
    DelayDeviceSnapshot(
      id: 'delay-1',
      gain: 1,
      pan: 0.5,
      bypassed: false,
      meterGainReductionDb: 0,
      meterInputLevel: 0,
      delayTimeMs: 250,
      delayFeedback: 0.4,
      delayTimeMode: timeMode,
      delayNoteCount: noteCount,
      delayBlurMode: blurMode,
    );

Widget _host(
  DelayDeviceSnapshot device,
  void Function(String, double) changed, {
  double textScale = 1,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: SizedBox(
          width: DelayFxPanel.designWidth,
          height: 300,
          child: DelayFxPanel(device: device, onParameterChanged: changed),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('delay labels select time units and blur modes', (tester) async {
    final changes = <(String, double)>[];
    await tester.pumpWidget(_host(_delay(), (id, value) {
      changes.add((id, value));
    }));

    expect(find.text('Time'), findsOneWidget);
    expect(find.text('No Blur'), findsOneWidget);
    expect(find.text('Input Ducking'), findsOneWidget);
    expect(find.text('Low Cut'), findsOneWidget);
    expect(find.text('High Cut'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('knob-label-menu-Time')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8th').last);
    await tester.pumpAndSettle();
    expect(changes, contains(('timeMode', 2.0)));

    await tester.tap(find.byKey(const ValueKey('knob-label-menu-No Blur')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wide Blur').last);
    await tester.pumpAndSettle();
    expect(changes, contains(('blurMode', 2.0)));
  });

  test('delay snapshot applies blur amount, ducking, and feedback EQ', () {
    final updated = _delay()
        .withParameter('blurAmount', 0.75)
        .withParameter('inputDucking', 0.6)
        .withParameter('lowCutHz', 180)
        .withParameter('highCutHz', 8400) as DelayDeviceSnapshot;

    expect(updated.delayBlurAmount, 0.75);
    expect(updated.delayInputDucking, 0.6);
    expect(updated.delayLowCutHz, 180);
    expect(updated.delayHighCutHz, 8400);
  });

  testWidgets('synced delay shows an integer note count without overflow',
      (tester) async {
    await tester.pumpWidget(
      _host(
        _delay(timeMode: 1, noteCount: 8, blurMode: 1),
        (_, __) {},
        textScale: 1.3,
      ),
    );

    expect(find.text('16th'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Soft Blur'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
