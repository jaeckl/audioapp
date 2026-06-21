import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/content_library/library_category.dart';
import 'package:audioapp/features/content_library/library_fly_in_panel.dart';
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

void main() {
  testWidgets('Library fly-in uses half width in landscape', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryFlyInPanel(
            snapshot: _emptySnapshot(),
            onClose: () {},
            onPreviewAudio: (_) {},
            onInsertAudio: (_) {},
            onImportAudio: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final positioned = tester.widgetList<Positioned>(
      find.descendant(of: find.byType(LibraryFlyInPanel), matching: find.byType(Positioned)),
    ).firstWhere((p) => p.left == 0 && p.width != null);
    expect(positioned.width, closeTo(800, 1));
  });

  testWidgets('Library fly-in uses full width in portrait', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryFlyInPanel(
            snapshot: _emptySnapshot(),
            onClose: () {},
            onPreviewAudio: (_) {},
            onInsertAudio: (_) {},
            onImportAudio: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final positioned = tester.widgetList<Positioned>(
      find.descendant(of: find.byType(LibraryFlyInPanel), matching: find.byType(Positioned)),
    ).firstWhere((p) => p.left == 0 && p.width != null);
    expect(positioned.width, closeTo(900, 1));
  });

  testWidgets('Library shows category menu and switches panes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryFlyInPanel(
            snapshot: _emptySnapshot(),
            onClose: () {},
            onPreviewAudio: (_) {},
            onInsertAudio: (_) {},
            onImportAudio: () {},
            initialCategory: LibraryCategory.audioClips,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audio clips'), findsOneWidget);
    expect(find.text('MIDI'), findsOneWidget);
    expect(find.text('Automation'), findsOneWidget);
    expect(find.text('Presets'), findsOneWidget);

    await tester.tap(find.text('MIDI'));
    // MIDI category shows loading spinner while manifest loads;
    // use pump() instead of pumpAndSettle() so the animating
    // indicator does not time out in headless test mode.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MIDI clips'), findsOneWidget);
  });

  testWidgets('Scrim tap closes library', (tester) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryFlyInPanel(
            snapshot: _emptySnapshot(),
            onClose: () => closed = true,
            onPreviewAudio: (_) {},
            onInsertAudio: (_) {},
            onImportAudio: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrim = find.byType(GestureDetector).first;
    await tester.tapAt(tester.getTopLeft(scrim) + const Offset(700, 200));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });
}