import 'package:audioapp/app/daw_shell.dart';
import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.audioapp.daw/engine');

  const bootstrapSnapshot = {
    'ok': true,
    'snapshot': {
      'bpm': 120,
      'playheadBeats': 0.0,
      'playing': false,
      'selectedTrackId': '',
      'master': {'id': 'master', 'name': 'Master', 'gain': 1.0},
      'tracks': [],
    },
  };

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'ping':
          return 'pong';
        case 'createProject':
          return bootstrapSnapshot;
        case 'getProjectSnapshot':
          return bootstrapSnapshot;
        case 'addTrack':
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'selectedTrackId': 'track-1',
              'tracks': [
                {
                  'id': 'track-1',
                  'name': 'Track 1',
                  'devices': [
                    {
                      'id': 'dev-1',
                      'type': 'simple_oscillator',
                      'parameters': {'frequency': 440.0},
                    },
                    {
                      'id': 'dev-2',
                      'type': 'track_gain',
                      'parameters': {'gain': 1.0},
                    },
                  ],
                  'midiClips': [],
                },
              ],
            },
          };
        case 'createMidiClip':
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'selectedTrackId': 'track-1',
              'tracks': [
                {
                  'id': 'track-1',
                  'name': 'Track 1',
                  'devices': [
                    {
                      'id': 'dev-1',
                      'type': 'simple_oscillator',
                      'parameters': {'frequency': 440.0},
                    },
                    {
                      'id': 'dev-2',
                      'type': 'track_gain',
                      'parameters': {'gain': 1.0},
                    },
                  ],
                  'midiClips': [
                    {
                      'id': 'clip-1',
                      'startBeat': 0.0,
                      'lengthBeats': 4.0,
                      'notes': [
                        {
                          'pitch': 60,
                          'startBeat': 0.0,
                          'durationBeats': 1.0,
                          'velocity': 100.0,
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          };
        case 'moveClip':
          final args = call.arguments as Map<dynamic, dynamic>?;
          final startBeat = (args?['startBeat'] as num?)?.toDouble() ?? 0.0;
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'selectedTrackId': 'track-1',
              'tracks': [
                {
                  'id': 'track-1',
                  'name': 'Track 1',
                  'devices': [
                    {
                      'id': 'dev-1',
                      'type': 'simple_oscillator',
                      'parameters': {'frequency': 440.0},
                    },
                    {
                      'id': 'dev-2',
                      'type': 'track_gain',
                      'parameters': {'gain': 1.0},
                    },
                  ],
                  'midiClips': [
                    {
                      'id': 'clip-1',
                      'startBeat': startBeat,
                      'lengthBeats': 4.0,
                      'notes': [
                        {
                          'pitch': 60,
                          'startBeat': 0.0,
                          'durationBeats': 1.0,
                          'velocity': 100.0,
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          };
        case 'setMidiClipNotes':
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'selectedTrackId': 'track-1',
              'tracks': [
                {
                  'id': 'track-1',
                  'name': 'Track 1',
                  'devices': [
                    {
                      'id': 'dev-1',
                      'type': 'simple_oscillator',
                      'parameters': {'frequency': 440.0},
                    },
                    {
                      'id': 'dev-2',
                      'type': 'track_gain',
                      'parameters': {'gain': 1.0},
                    },
                  ],
                  'midiClips': [
                    {
                      'id': 'clip-1',
                      'startBeat': 0.0,
                      'lengthBeats': 4.0,
                      'notes': [
                        {
                          'pitch': 60,
                          'startBeat': 0.0,
                          'durationBeats': 1.0,
                          'velocity': 100.0,
                        },
                        {
                          'pitch': 64,
                          'startBeat': 1.0,
                          'durationBeats': 1.0,
                          'velocity': 100.0,
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          };
        case 'saveProject':
          return {'ok': true, 'uri': 'file:///tmp/project.audioapp.zip', 'cancelled': false};
        case 'loadProject':
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'selectedTrackId': 'track-1',
              'tracks': [
                {
                  'id': 'track-1',
                  'name': 'Loaded Track',
                  'devices': [
                    {
                      'id': 'dev-1',
                      'type': 'simple_oscillator',
                      'parameters': {'frequency': 220.0},
                    },
                  ],
                  'midiClips': [],
                },
              ],
            },
          };
        case 'selectTrack':
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'selectedTrackId': 'track-1',
              'tracks': [
                {
                  'id': 'track-1',
                  'name': 'Track 1',
                  'devices': [
                    {
                      'id': 'dev-1',
                      'type': 'simple_oscillator',
                      'parameters': {'frequency': 440.0},
                    },
                    {
                      'id': 'dev-2',
                      'type': 'track_gain',
                      'parameters': {'gain': 1.0},
                    },
                  ],
                  'midiClips': [],
                },
              ],
            },
          };
        case 'setDeviceParameter':
        case 'setMasterGain':
        case 'setPlayheadBeats':
        case 'play':
        case 'stop':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('DAW shell shows transport header and bottom nav', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DawShell(bridge: EngineBridge(channel: channel))),
    );
    await tester.pumpAndSettle();

    expect(find.text('BPM 120'), findsOneWidget);
    expect(find.text('v0.1.0'), findsOneWidget);
    expect(find.bySemanticsLabel('Mixer'), findsOneWidget);
    expect(find.bySemanticsLabel('Library'), findsOneWidget);
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    expect(find.textContaining('Engine:'), findsNothing);

    await tester.tap(find.byTooltip('Add track'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('Adding track shows device strip with frequency slider', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: DawShell(bridge: EngineBridge(channel: channel))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add track'));
    await tester.pumpAndSettle();

    expect(find.text('Device strip — Track 1'), findsOneWidget);
    expect(find.text('Frequency'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('Track long-press menu adds MIDI clip', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: DawShell(bridge: EngineBridge(channel: channel))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add track'));
    await tester.pumpAndSettle();
    await tester.longPress(find.byTooltip('Track 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add MIDI Clip'));
    await tester.pumpAndSettle();

    expect(find.text('MIDI'), findsOneWidget);
  });

  testWidgets('Tapping MIDI clip opens piano roll and close returns', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: DawShell(bridge: EngineBridge(channel: channel))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add track'));
    await tester.pumpAndSettle();
    await tester.longPress(find.byTooltip('Track 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add MIDI Clip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MIDI'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Piano roll'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('BPM 120'), findsOneWidget);
  });

  testWidgets('Save and load project buttons in settings', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: DawShell(bridge: EngineBridge(channel: channel))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save project'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved project'), findsOneWidget);

    await tester.tap(find.text('Open project'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Loaded project'), findsOneWidget);
  });
}
