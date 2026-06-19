import 'package:audioapp/features/piano_roll/piano_roll_grid_sheet.dart';
import 'package:audioapp/features/piano_roll/piano_roll_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('grid sheet pills update on tap', (tester) async {
    var settings = const PianoRollGridSettings();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () {
                    PianoRollGridSheet.show(
                      context,
                      settings: settings,
                      onChanged: (next) => settings = next,
                    );
                  },
                  child: const Text('Grid'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();

    expect(find.text('1/8'), findsOneWidget);

    await tester.tap(find.text('1/8'));
    await tester.pumpAndSettle();

    expect(settings.snap, PianoRollSnap.eighth);
    expect(find.text('1/8'), findsOneWidget);
  });
}
