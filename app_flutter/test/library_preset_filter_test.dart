import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/content_library/device_preset_filter_list.dart';
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

LibraryManifest _testManifest({bool withVariedTypes = false}) {
  if (withVariedTypes) {
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
      ],
    });
  }
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
}

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
  testWidgets('device type filter chips shown for presets', (tester) async {
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Device type filter chips should be present
    expect(find.byType(DevicePresetFilterList), findsOneWidget);
    // All presets shown initially ("All" filter selected)
    expect(_presetTitles(), findsNWidgets(3));
  });

  testWidgets('device type filter narrowing by subtype', (tester) async {
    final manifest = _testManifest(withVariedTypes: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryContentPane(
            category: LibraryCategory.devicePresets,
            snapshot: _emptySnapshot(),
            presetManifest: manifest,
            onPreviewAudio: (_) {},
            onInsertAudio: (_) {},
            onImportAudio: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(_presetTitles(), findsNWidgets(3));

    // Tap "Synth" chip to filter by subtractive_synth
    await tester.tap(find.text('Synth'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Only "Warm pad" should remain (only subtractive_synth preset)
    expect(_presetTitles(), findsOneWidget);
    expect(find.text('Warm pad'), findsOneWidget);
  });
}