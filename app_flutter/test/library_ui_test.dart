import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/content_library/device_preset_filter_list.dart';
import 'package:audioapp/features/content_library/library_category.dart';
import 'package:audioapp/features/content_library/library_content_pane.dart';
import 'package:audioapp/features/content_library/library_header.dart';
import 'package:audioapp/features/content_library/library_manifest.dart';
import 'package:audioapp/features/content_library/library_preview_widget.dart';
import 'package:audioapp/features/content_library/library_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Finds the outer SizedBox of a LibraryPreviewWidget (unique by width 52).
Finder _previewSizedBox() => find.descendant(
      of: find.byType(LibraryPreviewWidget),
      matching: find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 52,
      ),
    );

/// Finds CustomPaint widgets inside a ClipRRect (only waveform branch has this).
Finder _waveformCustomPaint() => find.descendant(
      of: find.byType(ClipRRect),
      matching: find.byType(CustomPaint),
    );

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

ProjectSnapshot _snapshotWithSamples() {
  return const ProjectSnapshot(
    bpm: 120,
    playheadBeats: 0,
    playing: false,
    loopEnabled: false,
    recordArmed: false,
    selectedTrackId: '',
    master: MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1),
    tracks: [],
    samples: [
      SampleLibraryEntrySnapshot(
        id: 'kick',
        name: 'Kick',
        source: 'bundled',
        durationBeats: 4,
        waveformPeaks: [0.1, 0.5, 0.9],
      ),
      SampleLibraryEntrySnapshot(
        id: 'snare',
        name: 'Snare',
        source: 'bundled',
        durationBeats: 8,
        waveformPeaks: [0.2, 0.6, 0.8],
      ),
    ],
  );
}

LibraryManifest _variedManifest() {
  return LibraryManifest.fromJson({
    'presets': [
      {
        'id': 'preset:synth-warm-pad',
        'title': 'Warm pad',
        'subtitle': 'Unison',
        'deviceType': 'subtractive_synth',
        'tags': ['pad', 'warm', 'factory'],
      },
      {
        'id': 'preset:bass-synth',
        'title': 'Bass',
        'subtitle': 'Sub octave',
        'deviceType': 'bass_synth',
        'tags': ['bass', 'factory'],
      },
      {
        'id': 'preset:sampler-kick',
        'title': 'Kick drum',
        'subtitle': 'Analog',
        'deviceType': 'simple_sampler',
        'tags': ['kick', 'factory'],
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
}

/// Finds bold title texts inside the ListView.
Finder _presetTitles() => find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.fontWeight == FontWeight.w600 &&
            widget.maxLines == 1,
      ),
    );

/// Finds Container widgets with a non-null border (selection highlight).
Finder _containersWithBorder() => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border != null,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ====================================================================
  // 1. LibraryPreviewWidget — compact size
  // ====================================================================
  group('LibraryPreviewWidget — compact size', () {
    testWidgets('renders at 52×36 when no peaks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LibraryPreviewWidget(peaks: null)),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(_previewSizedBox());
      expect(sizedBox.width, 52);
      expect(sizedBox.height, 36);
    });

    testWidgets('renders at 52×36 when peaks provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LibraryPreviewWidget(peaks: [0.1, 0.5, 0.9]),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(_previewSizedBox());
      expect(sizedBox.width, 52);
      expect(sizedBox.height, 36);
    });
  });

  // ====================================================================
  // 2. LibraryPreviewWidget — waveform rendering
  // ====================================================================
  group('LibraryPreviewWidget — waveform rendering', () {
    testWidgets('shows waveform ClipRRect/CustomPaint with peaks',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LibraryPreviewWidget(peaks: [0.1, 0.5, 0.9]),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
      expect(_waveformCustomPaint(), findsOneWidget);
    });

    testWidgets('shows loading spinner when peaks is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LibraryPreviewWidget(peaks: null)),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('shows error placeholder when peaks is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LibraryPreviewWidget(peaks: [])),
        ),
      );

      expect(find.byType(ClipRRect), findsNothing);
      expect(
          find.byIcon(Icons.auto_awesome_mosaic_outlined), findsOneWidget);
    });
  });

  // ====================================================================
  // 3. DevicePresetFilterList — renders chips
  // ====================================================================
  group('DevicePresetFilterList — renders chips', () {
    testWidgets('renders kDevicePresetFilters count of entries',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DevicePresetFilterList(onFilterChanged: (_) {}),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Sampler'), findsOneWidget);
      expect(find.text('Synth'), findsOneWidget);
      expect(find.text('Kick'), findsOneWidget);
      expect(find.text('Snare'), findsOneWidget);
      expect(find.text('Clap'), findsOneWidget);
      expect(find.text('Cymbal'), findsOneWidget);
      expect(find.text('Hi-hat'), findsOneWidget);
      // Scroll horizontally to reveal off-screen chips
      final listView = find.byType(ListView).first;
      await tester.drag(listView, const Offset(-400, 0));
      await tester.pump();
      expect(find.text('Bass Synth'), findsOneWidget);
      expect(find.text('Dynamics'), findsOneWidget);
    });

    testWidgets('first chip label is Sampler', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DevicePresetFilterList(onFilterChanged: (_) {}),
          ),
        ),
      );

      expect(find.text('Sampler'), findsOneWidget);
    });

    testWidgets('tapping a chip calls onFilterChanged with device type',
        (tester) async {
      String? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DevicePresetFilterList(
              onFilterChanged: (type) => captured = type,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Synth'));
      expect(captured, 'subtractive_synth');
    });

    testWidgets('tapping All calls onFilterChanged with null',
        (tester) async {
      String? captured = 'simple_sampler';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DevicePresetFilterList(
              selectedType: captured,
              onFilterChanged: (type) => captured = type,
            ),
          ),
        ),
      );

      await tester.tap(find.text('All'));
      expect(captured, isNull);
    });
  });

  // ====================================================================
  // 4. LibraryContentPane — selection behavior
  // ====================================================================
  group('LibraryContentPane — selection behavior', () {
    testWidgets('tapping audio item calls onItemSelected with item id',
        (tester) async {
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryContentPane(
              category: LibraryCategory.audioClips,
              snapshot: _snapshotWithSamples(),
              onPreviewAudio: (_) {},
              onInsertAudio: (_) {},
              onImportAudio: () {},
              onItemSelected: (id) => selectedId = id,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Kick'));
      await tester.pump();

      expect(selectedId, 'sample:kick');
    });

    testWidgets('tapping a different item changes selection',
        (tester) async {
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryContentPane(
              category: LibraryCategory.audioClips,
              snapshot: _snapshotWithSamples(),
              onPreviewAudio: (_) {},
              onInsertAudio: (_) {},
              onImportAudio: () {},
              onItemSelected: (id) => selectedId = id,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Kick'));
      await tester.pump();
      expect(selectedId, 'sample:kick');

      await tester.tap(find.text('Snare'));
      await tester.pump();
      expect(selectedId, 'sample:snare');
    });

    testWidgets('tapping the same item is a no-op (already selected)',
        (tester) async {
      String? selectedId;
      var callCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryContentPane(
              category: LibraryCategory.audioClips,
              snapshot: _snapshotWithSamples(),
              onPreviewAudio: (_) {},
              onInsertAudio: (_) {},
              onImportAudio: () {},
              onItemSelected: (id) {
                selectedId = id;
                callCount++;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Kick'));
      await tester.pump();
      expect(selectedId, 'sample:kick');
      expect(callCount, 1);

      // Second tap on same item also calls onItemSelected (select + preview)
      await tester.tap(find.text('Kick'));
      await tester.pump();
      expect(selectedId, 'sample:kick');
      expect(callCount, 2);
    });
  });

  // ====================================================================
  // 5. LibraryHeader — insert button state
  // ====================================================================
  group('LibraryHeader — insert button state', () {
    testWidgets('shows disabled Insert when selectedItemId is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryHeader(
              onClose: () async {},
              selectedItemId: null,
              onInsert: null,
              accent: LibraryTheme.accent,
            ),
          ),
        ),
      );

      final button = find.widgetWithText(FilledButton, 'Insert');
      final filled = tester.widget<FilledButton>(button);
      expect(filled.onPressed, isNull);
    });

    testWidgets('shows enabled Insert with a non-null ID',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryHeader(
              onClose: () async {},
              selectedItemId: 'sample:kick',
              onInsert: () {},
              accent: LibraryTheme.accent,
            ),
          ),
        ),
      );

      final button = find.widgetWithText(FilledButton, 'Insert');
      final filled = tester.widget<FilledButton>(button);
      expect(filled.onPressed, isNotNull);
    });

    testWidgets('pressing enabled Insert calls onInsert', (tester) async {
      var inserted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryHeader(
              onClose: () async {},
              selectedItemId: 'sample:kick',
              onInsert: () => inserted = true,
              accent: LibraryTheme.accent,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Insert'));
      expect(inserted, isTrue);
    });

    testWidgets('button text is Insert', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryHeader(
              onClose: () async {},
              selectedItemId: null,
              onInsert: null,
              accent: LibraryTheme.accent,
            ),
          ),
        ),
      );

      expect(find.text('Insert'), findsOneWidget);
    });
  });

  // ====================================================================
  // 6. Selection highlight in tiles
  // ====================================================================
  group('Selection highlight in tiles', () {
    testWidgets('selected item shows a border highlight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryContentPane(
              category: LibraryCategory.audioClips,
              snapshot: _snapshotWithSamples(),
              onPreviewAudio: (_) {},
              onInsertAudio: (_) {},
              onImportAudio: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(_containersWithBorder(), findsNothing);

      await tester.tap(find.text('Kick'));
      await tester.pump();

      expect(_containersWithBorder(), findsAtLeastNWidgets(1));
    });

    testWidgets('switching selection moves border highlight',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryContentPane(
              category: LibraryCategory.audioClips,
              snapshot: _snapshotWithSamples(),
              onPreviewAudio: (_) {},
              onInsertAudio: (_) {},
              onImportAudio: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap first item → border appears
      await tester.tap(find.text('Kick'));
      await tester.pump();
      expect(_containersWithBorder(), findsAtLeastNWidgets(1));

      // Tap a different item → border still exists (now on Snare)
      await tester.tap(find.text('Snare'));
      await tester.pump();
      expect(_containersWithBorder(), findsAtLeastNWidgets(1));
    });
  });

  // ====================================================================
  // 7. Device preset filter integration
  // ====================================================================
  group('Device preset filter integration', () {
    testWidgets('device filter chips shown for presets category',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryContentPane(
              category: LibraryCategory.devicePresets,
              snapshot: _emptySnapshot(),
              presetManifest: _variedManifest(),
              onPreviewAudio: (_) {},
              onInsertAudio: (_) {},
              onImportAudio: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DevicePresetFilterList), findsOneWidget);
      expect(_presetTitles(), findsNWidgets(4));
    });

    testWidgets('filtering by device type narrows results',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryContentPane(
              category: LibraryCategory.devicePresets,
              snapshot: _emptySnapshot(),
              presetManifest: _variedManifest(),
              onPreviewAudio: (_) {},
              onInsertAudio: (_) {},
              onImportAudio: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_presetTitles(), findsNWidgets(4));

      // Tap "Synth" to filter by subtractive_synth
      await tester.tap(find.text('Synth'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_presetTitles(), findsNWidgets(2));
      expect(find.text('Warm pad'), findsOneWidget);
      expect(find.text('Pluck'), findsOneWidget);
      expect(find.text('Kick drum'), findsNothing);
      expect(find.text('Bass'), findsNothing);

      // Tap "All" to reset
      await tester.tap(find.text('All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_presetTitles(), findsNWidgets(4));
    });
  });
}