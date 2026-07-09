import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/envelope_properties_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EnvelopePropertiesPanel shows ADSR knobs', (tester) async {
    await _pump(tester, curveType: 0);

    expect(find.text('Atk'), findsOneWidget);
    expect(find.text('Hold'), findsNothing);
    expect(find.text('Dec'), findsOneWidget);
    expect(find.text('Sus'), findsOneWidget);
    expect(find.text('Rel'), findsOneWidget);
  });

  testWidgets('EnvelopePropertiesPanel shows ASR knobs', (tester) async {
    await _pump(tester, curveType: 1);

    expect(find.text('Atk'), findsOneWidget);
    expect(find.text('Hold'), findsNothing);
    expect(find.text('Dec'), findsNothing);
    expect(find.text('Sus'), findsOneWidget);
    expect(find.text('Rel'), findsOneWidget);
  });

  testWidgets('EnvelopePropertiesPanel shows ADR knobs', (tester) async {
    await _pump(tester, curveType: 2);

    expect(find.text('Atk'), findsOneWidget);
    expect(find.text('Hold'), findsNothing);
    expect(find.text('Dec'), findsOneWidget);
    expect(find.text('Sus'), findsNothing);
    expect(find.text('Rel'), findsOneWidget);
  });

  testWidgets('EnvelopePropertiesPanel shows AHDSR knobs', (tester) async {
    await _pump(tester, curveType: 3);

    expect(find.text('Atk'), findsOneWidget);
    expect(find.text('Hold'), findsOneWidget);
    expect(find.text('Dec'), findsOneWidget);
    expect(find.text('Sus'), findsOneWidget);
    expect(find.text('Rel'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, {required int curveType}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 260,
            child: EnvelopePropertiesPanel(
              mod: LfoSnapshot(id: 1, type: 'envelope', curveType: curveType),
              onUpdate: (_, __) async {},
            ),
          ),
        ),
      ),
    ),
  );
}
