import 'package:audioapp/features/device_strip/device_automation_knob.dart';
import 'package:audioapp/features/device_strip/rotary_knob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long-press knob invokes onAutomateParameter', (tester) async {
    String? automatedParam;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: deviceAutomationKnob(
              label: 'Filter',
              value: 0.5,
              onChanged: (_) {},
              paramId: 'filterCutoff',
              accentColor: Colors.orange,
              onAutomateParameter: (paramId) => automatedParam = paramId,
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(RotaryKnob));
    await tester.pumpAndSettle();

    expect(automatedParam, 'filterCutoff');
  });
}
