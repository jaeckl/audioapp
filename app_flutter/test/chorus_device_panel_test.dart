import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/time_fx_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChorusDeviceSnapshot _chorus({double modeMorph = 0}) => ChorusDeviceSnapshot(
      id: 'chorus-1',
      gain: 1,
      pan: .5,
      bypassed: false,
      meterGainReductionDb: 0,
      meterInputLevel: 0,
      modeMorph: modeMorph,
    );

Widget _host(
  ChorusDeviceSnapshot device,
  void Function(String, double) changed, {
  Set<String> modulatedParams = const {},
  Map<String, double> modulationAmounts = const {},
  int? connectModeLfoId,
  void Function(String, double)? onModulationAssign,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: ChorusFxPanel.designWidth,
        height: 280,
        child: ChorusFxPanel(
          device: device,
          onParameterChanged: changed,
          modulatedParams: modulatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('chorus mode group selects all four morph anchors',
      (tester) async {
    final changes = <(String, double)>[];
    await tester.pumpWidget(_host(_chorus(), (id, value) {
      changes.add((id, value));
    }));

    for (final mode in ['Classic', 'Ensemble', 'Dimension', 'Drift']) {
      expect(find.text(mode), findsOneWidget);
    }
    expect(find.text('Phase'), findsOneWidget);
    expect(find.text('Shape'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chorus-mode-Dimension')));
    expect(changes, contains(('modeMorph', 2.0)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mode group pulses for linking and shows a horizontal mod line',
      (tester) async {
    await tester.pumpWidget(_host(
      _chorus(modeMorph: 1),
      (_, __) {},
      connectModeLfoId: 7,
    ));

    final groupFinder = find.byKey(const ValueKey('chorus-mode-group'));
    final before = tester.widget<Container>(groupFinder).decoration;
    await tester.pump(const Duration(milliseconds: 500));
    final after = tester.widget<Container>(groupFinder).decoration;
    expect(after, isNot(equals(before)));
    expect(find.byKey(const ValueKey('chorus-mode-modulation-line')),
        findsNothing);

    await tester.pumpWidget(_host(
      _chorus(modeMorph: 1),
      (_, __) {},
      modulatedParams: const {'modeMorph'},
      modulationAmounts: const {'modeMorph': .4},
    ));
    final lineFinder =
        find.byKey(const ValueKey('chorus-mode-modulation-line'));
    expect(lineFinder, findsOneWidget);
    final lineSize = tester.getSize(lineFinder);
    expect(lineSize.width, greaterThan(lineSize.height));
  });

  testWidgets('long-press drag links modulation to the whole mode group',
      (tester) async {
    final assignments = <(String, double)>[];
    await tester.pumpWidget(_host(
      _chorus(),
      (_, __) {},
      connectModeLfoId: 3,
      onModulationAssign: (id, amount) => assignments.add((id, amount)),
    ));

    final center = tester.getCenter(
      find.byKey(const ValueKey('chorus-mode-group')),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(find.byKey(const ValueKey('chorus-mode-modulation-line')),
        findsOneWidget);
    await gesture.up();
    await tester.pump();

    expect(assignments, hasLength(1));
    expect(assignments.single.$1, 'modeMorph');
    expect(assignments.single.$2, greaterThan(0));
  });

  testWidgets('each chorus anchor exposes its own parameter bank',
      (tester) async {
    await tester.pumpWidget(_host(_chorus(modeMorph: 1), (_, __) {}));
    expect(find.text('Voices'), findsOneWidget);
    expect(find.text('Drift'), findsNWidgets(2));

    await tester.pumpWidget(_host(_chorus(modeMorph: 2), (_, __) {}));
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Low Cut'), findsOneWidget);
    expect(find.text('High Cut'), findsOneWidget);

    await tester.pumpWidget(_host(_chorus(modeMorph: 3), (_, __) {}));
    expect(find.text('Wander'), findsOneWidget);
    expect(find.text('Stereo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('chorus snapshot parses banks and updates semantic parameters', () {
    final snapshot = DeviceSnapshot.fromMap({
      'id': 'chorus-map',
      'type': 'chorus',
      'parameters': {
        'modeMorph': 1.5,
        'classic': [.1, .2, .3, .4, .5, .6],
        'ensemble': [.2, .3, .4, .5, .6, .7],
        'dimension': [.3, .4, .5, .6, .7, .8],
        'drift': [.4, .5, .6, .7, .8, .9],
      },
      'outputPanel': {'outputMix': .45, 'outputWidth': .8},
    }) as ChorusDeviceSnapshot;

    expect(snapshot.modeMorph, 1.5);
    expect(snapshot.outputMix, .45);
    final updated = snapshot.withParameter('driftWander', .95);
    expect(updated.drift[2], .95);
    expect(updated.ensemble[2], .4);
  });
}
