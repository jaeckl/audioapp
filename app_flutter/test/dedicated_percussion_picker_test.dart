import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/features/device_strip/device_picker_sheet.dart';

void main() {
  testWidgets('device picker lists dedicated percussion generators',
      (tester) async {
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

    expect(find.text('Hi-Hat'), findsOneWidget);
    expect(find.text('Closed to open metallic hats'), findsOneWidget);
    expect(find.text('Ride'), findsOneWidget);
    expect(find.text('Tom'), findsOneWidget);
    expect(find.text('Rimshot'), findsOneWidget);
  });
}
