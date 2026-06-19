import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/content_library/library_category.dart';
import 'package:audioapp/features/content_library/library_content_pane.dart';
import 'package:audioapp/features/content_library/library_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectSnapshot _emptySnapshot() => const ProjectSnapshot(
      bpm: 120,
      playheadBeats: 0,
      playing: false,
      loopEnabled: false,
      recordArmed: false,
      selectedTrackId: '',
      master: MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1),
      tracks: [],
      samples: [],
    );

LibraryManifest _testManifest() => LibraryManifest.fromJson({
      'presets': [
        {
          'id': 'preset:synth-warm-pad',
          'title': 'Warm pad',
          'subtitle': 'Unison',
          'deviceType': 'subtractive_synth',
          'tags': ['pad', 'warm', 'factory'],
        },
        {
          'id': 'preset:synth-bass',
          'title': 'Synth bass',
          'subtitle': 'Square stack',
          'deviceType': 'subtractive_synth',
          'tags': ['bass', 'dark', 'factory'],
        },
        {
          'id': 'preset:synth-pluck',
          'title': 'Pluck',
          'subtitle': 'Short amp',
          'deviceType': 'subtractive_synth',
          'tags': ['pluck', 'bright', 'factory'],
        },
      ],
    });

Finder _presetTitles() => find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.fontWeight == FontWeight.w600 &&
            widget.maxLines == 1,
      ),
    );

void main() {
  testWidgets('preset tag chips filter list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryContentPane(
            category: LibraryCategory.devicePresets,
            snapshot: _emptySnapshot(),
            presetManifest: _testManifest(),
            onPreviewAudio: (_) {},
            onInsertAudio: (_) {},
            onImportAudio: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_presetTitles(), findsNWidgets(3));

    await tester.tap(find.text('Bass'));
    await tester.pumpAndSettle();

    expect(_presetTitles(), findsOneWidget);
    expect(find.text('Synth bass'), findsOneWidget);
  });

  testWidgets('role and character filters combine across groups', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryContentPane(
            category: LibraryCategory.devicePresets,
            snapshot: _emptySnapshot(),
            presetManifest: _testManifest(),
            onPreviewAudio: (_) {},
            onInsertAudio: (_) {},
            onImportAudio: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pad'));
    await tester.pumpAndSettle();
    expect(find.text('Warm pad'), findsOneWidget);

    await tester.tap(find.text('Bright'));
    await tester.pumpAndSettle();
    expect(find.text('No presets match these filters.'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(_presetTitles(), findsNWidgets(3));
  });
}
