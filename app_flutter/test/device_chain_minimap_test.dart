import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/content_library/library_fly_in_panel.dart';
import 'package:audioapp/features/device_strip/device_chain_layout.dart';
import 'package:audioapp/features/device_strip/device_chain_minimap.dart';
import 'package:audioapp/features/device_strip/device_chain_screen.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final track = TrackSnapshot(
    id: 'track-1',
    name: 'Track 1',
    devices: [
      DeviceSnapshot.fromMap({
        'id': 'dev-1',
        'type': 'simple_sampler',
        'parameters': {'gain': 1.0, 'sampleId': ''},
      }),
      DeviceSnapshot.fromMap({
        'id': 'dev-2',
        'type': 'simple_oscillator',
        'parameters': {'frequencyHz': 440.0},
      }),
      DeviceSnapshot.fromMap({
        'id': 'dev-3',
        'type': 'track_gain',
        'parameters': {'gain': 1.0},
      }),
    ],
    midiClips: [],
    sampleClips: [],
  );

  final snapshot = ProjectSnapshot(
    bpm: 120,
    selectedTrackId: track.id,
    playheadBeats: 0,
    playing: false,
    loopEnabled: false,
    recordArmed: false,
    master: const MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1),
    samples: const [],
    tracks: [track],
  );

  test('DeviceChainLayout sums slot and separator widths', () {
    final width = DeviceChainLayout.contentWidth(track, DeviceStripSlotDensity.fullscreen);
    expect(width, greaterThan(900));
  });

  testWidgets('DeviceChainScreen shows close button and minimap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceChainScreen(
          snapshot: snapshot,
          track: track,
          samples: const [],
          playing: false,
          onSamplerParameterChanged: (_, __, ___) {},
          onOpenSamplerEditor: (_, __) {},
          onFrequencyChanged: (_, __) {},
          onInsertDevice: (_) {},
          onBypassToggle: (_, __) {},
          onPreviewAudio: (_) {},
          onAssignSamplerSample: (_, __) {},
          onImportAudio: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byType(DeviceChainMinimap), findsOneWidget);
    expect(find.text('Swipe horizontally'), findsNothing);
  });

  testWidgets('DeviceChainScreen library button opens fly-in overlay', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceChainScreen(
          snapshot: snapshot,
          track: track,
          samples: const [],
          playing: false,
          onSamplerParameterChanged: (_, __, ___) {},
          onOpenSamplerEditor: (_, __) {},
          onFrequencyChanged: (_, __) {},
          onInsertDevice: (_) {},
          onBypassToggle: (_, __) {},
          onPreviewAudio: (_) {},
          onAssignSamplerSample: (_, __) {},
          onImportAudio: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open sample library'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryFlyInPanel), findsOneWidget);
    expect(find.text('Audio clips'), findsOneWidget);
  });
}
