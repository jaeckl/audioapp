import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/features/device_strip/device_picker_sheet.dart';

void main() {
  testWidgets('device picker lists dynamics FX', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDevicePickerSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Effects'), findsOneWidget);
    expect(find.text('Gate'), findsOneWidget);
    expect(find.text('Compressor'), findsOneWidget);
    expect(find.text('Expander'), findsOneWidget);
    expect(find.text('Limiter'), findsOneWidget);
  });
}
