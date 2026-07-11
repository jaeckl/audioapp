import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_chain_row.dart';
import 'package:audioapp/features/device_strip/device_strip.dart';
import 'package:audioapp/features/device_strip/device_strip_card.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:audioapp/features/device_strip/device_strip_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeviceChainRow shows insert control after each device', (tester) async {
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
          'type': 'track_gain',
          'parameters': {'gain': 1.0},
        }),
      ],
      midiClips: [],
      sampleClips: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceChainRow(
            track: track,
            samples: const [],
            playing: false,
            bpm: 120,
            density: DeviceStripSlotDensity.strip,
            onSamplerParameterChanged: (_, __, ___) {},
            onOpenSamplerEditor: (_, __) {},
            onFrequencyChanged: (_, __) {},
            onInsertDevice: (_) async => null,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(DeviceStripCard), findsOneWidget);
    expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    expect(find.text('Wave'), findsOneWidget);
    expect(find.text('Tone'), findsOneWidget);
  });

  testWidgets('collapsed strip uses header-only cards and global expand', (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceStrip(
            snapshot: snapshot,
            track: track,
            samples: const [],
            playing: false,
            playheadBeats: 0,
            onSamplerParameterChanged: (_, __, ___) {},
            onAssignSamplerSample: (_, __) {},
            onOpenSamplerEditor: (_, __) {},
            onPreviewSample: (_) {},
            onImportSamples: () async => const [],
            onFrequencyChanged: (_, __) {},
            onAddDevice: (_, __, ___) async => snapshot,
            onBypassToggle: (_, __) {},
            onRemoveDevice: (_, __) async => null,
            onOpenDeviceLibrary: (_, __) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.unfold_more), findsOneWidget);
    expect(find.byIcon(Icons.unfold_less), findsNothing);
    expect(find.text('SAMPLER'), findsOneWidget);
  });

  testWidgets('frozen track dims pre-gain devices and disables insert', (tester) async {
    var insertCalls = 0;
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
          'type': 'track_gain',
          'parameters': {'gain': 1.0},
        }),
      ],
      midiClips: [],
      sampleClips: [],
      freeze: const TrackFreezeSnapshot(enabled: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceChainRow(
            track: track,
            samples: const [],
            playing: false,
            bpm: 120,
            density: DeviceStripSlotDensity.strip,
            onSamplerParameterChanged: (_, __, ___) {},
            onOpenSamplerEditor: (_, __) {},
            onFrequencyChanged: (_, __) {},
            onInsertDevice: (_) async {
              insertCalls++;
              return null;
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(insertCalls, 0);

    final dimmed = tester.widgetList<Opacity>(
      find.descendant(
        of: find.byType(DeviceStripSlot),
        matching: find.byType(Opacity),
      ),
    );
    expect(
      dimmed.where((o) => o.opacity == DeviceStripTheme.frozenPreGainOpacity).length,
      1,
    );
  });
}
