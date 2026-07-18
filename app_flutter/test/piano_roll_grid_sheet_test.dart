import 'package:audioapp/features/piano_roll/piano_roll_grid_sheet.dart';
import 'package:audioapp/features/piano_roll/piano_roll_metrics.dart';
import 'package:audioapp/features/piano_roll/piano_roll_scale.dart';
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

    expect(find.text('Note length'), findsOneWidget);
    expect(find.text('Resolution'), findsOneWidget);

    await tester.tap(find.text('1/16').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1/8').first);
    await tester.pumpAndSettle();

    expect(settings.snap, PianoRollSnap.eighth);
    expect(find.text('1/8'), findsOneWidget);
  });

  testWidgets('draw sheet owns note length and chord controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return FilledButton(
              onPressed: () => PianoRollGridSheet.showDraw(
                context,
                settings: const PianoRollGridSettings(),
                scaleSettings: const PianoRollScaleSettings(),
                onChanged: (_) {},
                onScaleChanged: (_) {},
                showScaleControls: true,
              ),
              child: const Text('Draw'),
            );
          }),
        ),
      ),
    );

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();

    expect(find.text('Note length'), findsOneWidget);
    expect(find.text('Chord mode'), findsOneWidget);
    expect(find.text('Note snap'), findsNothing);
  });

  testWidgets('view sheet note length sets insert default', (tester) async {
    var settings = const PianoRollGridSettings(defaultNoteBeats: 0.25);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () {
                  PianoRollGridSheet.showView(
                    context,
                    settings: settings,
                    onChanged: (next) => settings = next,
                    viewRangeBars: 4,
                    onViewRangeChanged: (_) {},
                  );
                },
                child: const Text('View'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(find.text('Note length'), findsOneWidget);
    expect(find.text('Resolution'), findsOneWidget);

    await tester.tap(find.text('1/16').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 bar').last);
    await tester.pumpAndSettle();

    expect(settings.defaultNoteBeats, 4.0);
    expect(settings.insertNoteDurationBeats, 4.0);
  });
}
