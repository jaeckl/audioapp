import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_chain_layout.dart';
import 'package:audioapp/features/device_strip/device_chain_row.dart';
import 'package:audioapp/features/device_strip/device_insert_slot.dart';
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

  testWidgets('nested chain inside chain shows CHAIN strip and insert', (tester) async {
    tester.view.physicalSize = const Size(2400, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final innerChain = ChainDeviceSnapshot(
      id: 'chain-inner',
      bypassed: false,
      devices: [
        DeviceSnapshot.fromMap({
          'id': 'comp-1',
          'type': 'compressor',
          'bypass': false,
          'parameters': const {},
        }),
      ],
    );
    final outerChain = ChainDeviceSnapshot(
      id: 'chain-outer',
      bypassed: false,
      devices: [innerChain],
    );
    final track = TrackSnapshot(
      id: 'track-1',
      name: 'Track 1',
      devices: [outerChain],
      midiClips: const [],
      sampleClips: const [],
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
    await tester.pumpAndSettle();

    final chainStripTitles = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'CHAIN' &&
          widget.style?.fontWeight == FontWeight.w800,
    );
    expect(chainStripTitles, findsNWidgets(2));
    expect(find.byType(DeviceInsertSlot), findsAtLeast(2));
  });

  testWidgets('nested spectral in chain shows PRE POST when toggled', (tester) async {
    tester.view.physicalSize = const Size(3200, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final spectral = SpectralLoudSplitDeviceSnapshot(
      id: 'sl-nested',
      type: 'spectral_loud_split',
      bypassed: false,
      preFxDevices: [
        DeviceSnapshot.fromMap({
          'id': 'pre-fx',
          'type': 'filter',
          'bypass': false,
          'parameters': const {},
        }),
      ],
      postFxDevices: [
        DeviceSnapshot.fromMap({
          'id': 'post-fx',
          'type': 'delay',
          'bypass': false,
          'parameters': const {},
        }),
      ],
    );
    final chain = ChainDeviceSnapshot(
      id: 'chain-outer',
      bypassed: false,
      devices: [spectral],
    );
    final track = TrackSnapshot(
      id: 'track-1',
      name: 'Track 1',
      devices: [chain],
      midiClips: const [],
      sampleClips: const [],
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
    await tester.pumpAndSettle();

    expect(find.text('PRE'), findsNothing);
    expect(find.text('POST'), findsNothing);

    await tester.tap(find.text('PRE FX'));
    await tester.pumpAndSettle();
    expect(find.text('PRE'), findsOneWidget);

    await tester.tap(find.text('POST FX'));
    await tester.pumpAndSettle();
    expect(find.text('POST'), findsOneWidget);
  });

  test('DeviceChainLayout contentWidth grows with nested expanded hosts', () {
    const density = DeviceStripSlotDensity.strip;
    final emptyOuter = ChainDeviceSnapshot(
      id: 'chain-empty',
      bypassed: false,
      devices: const [],
    );
    final innerChain = ChainDeviceSnapshot(
      id: 'chain-inner',
      bypassed: false,
      devices: [
        DeviceSnapshot.fromMap({
          'id': 'fx-1',
          'type': 'compressor',
          'bypass': false,
          'parameters': const {},
        }),
      ],
    );
    final nestedOuter = ChainDeviceSnapshot(
      id: 'chain-outer',
      bypassed: false,
      devices: [innerChain],
    );

    final emptyTrack = TrackSnapshot(
      id: 'track-1',
      name: 'Track 1',
      devices: [emptyOuter],
      midiClips: const [],
      sampleClips: const [],
    );
    final nestedTrack = TrackSnapshot(
      id: 'track-1',
      name: 'Track 1',
      devices: [nestedOuter],
      midiClips: const [],
      sampleClips: const [],
    );

    final emptyWidth = DeviceChainLayout.contentWidth(emptyTrack, density);
    final nestedWidth = DeviceChainLayout.contentWidth(nestedTrack, density);
    expect(nestedWidth, greaterThan(emptyWidth));

    final spectral = SpectralLoudSplitDeviceSnapshot(
      id: 'sl-1',
      type: 'spectral_loud_split',
      bypassed: false,
    );
    final chainWithSpectral = ChainDeviceSnapshot(
      id: 'chain-sl',
      bypassed: false,
      devices: [spectral],
    );
    final spectralTrack = TrackSnapshot(
      id: 'track-1',
      name: 'Track 1',
      devices: [chainWithSpectral],
      midiClips: const [],
      sampleClips: const [],
    );
    final baseWidth =
        DeviceChainLayout.contentWidth(spectralTrack, density);
    final prePostWidth = DeviceChainLayout.contentWidth(
      spectralTrack,
      density,
      expand: DeviceChainExpandState(
        synthNoteFxExpanded: {'sl-1': true},
        synthAudioFxExpanded: {'sl-1': true},
        slBandExpanded: {'sl-1': {0}},
      ),
    );
    expect(prePostWidth, greaterThan(baseWidth));
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
