import 'package:audioapp/app/daw_shell.dart';
import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:audioapp/features/play/mpc_pad_grid.dart';
import 'package:audioapp/features/device_strip/device_insert_slot.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.audioapp.daw/engine');

  int? lastNoteOnPitch;
  double? lastNoteOnVelocity;
  double? lastModulation;
  double? lastPitchBend;
  double? peakModulation;
  double? peakPitchBend;
  bool mockWithSamplerDefault = false;

  const bootstrapSnapshot = {
    'ok': true,
    'snapshot': {
      'bpm': 120,
      'playheadBeats': 0.0,
      'playing': false,
      'recordArmed': false,
      'selectedTrackId': '',
      'master': {'id': 'master', 'name': 'Master', 'gain': 1.0},
      'tracks': [],
    },
  };

  setUp(() {
    lastNoteOnPitch = null;
    lastNoteOnVelocity = null;
    lastModulation = null;
    lastPitchBend = null;
    peakModulation = null;
    peakPitchBend = null;
    mockWithSamplerDefault = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'ping':
          return 'pong';
        case 'createProject':
          return bootstrapSnapshot;
        case 'getProjectSnapshot':
          return bootstrapSnapshot;
        case 'getTransportState':
          return {
            'ok': true,
            'playheadBeats': 0.0,
            'playing': false,
            'bpm': 120,
            'loopEnabled': true,
            'loopLengthBeats': 16.0,
          };
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
                  'devices': mockWithSamplerDefault
                      ? [
                          {
                            'id': 'dev-1',
                            'type': 'simple_sampler',
                            'parameters': {'gain': 1.0, 'sampleId': '', 'bypass': false},
                          },
                          {
                            'id': 'dev-2',
                            'type': 'track_gain',
                            'parameters': {'gain': 1.0},
                          },
                        ]
                      : [
                          {
                            'id': 'dev-1',
                            'type': 'track_gain',
                            'parameters': {'gain': 1.0},
                          },
                        ],
                  'midiClips': [],
                },
              ],
            },
          };
        case 'addDeviceToTrack':
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
                      'type': 'simple_sampler',
                      'parameters': {'gain': 1.0, 'sampleId': '', 'bypass': false},
                    },
                    {
                      'id': 'dev-3',
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
                      'type': 'simple_sampler',
                      'parameters': {'gain': 1.0, 'sampleId': '', 'bypass': false},
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
                      'notes': [],
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
                      'type': 'simple_sampler',
                      'parameters': {'gain': 1.0, 'sampleId': '', 'bypass': false},
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
                      'type': 'simple_sampler',
                      'parameters': {'gain': 1.0, 'sampleId': '', 'bypass': false},
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
                      'type': 'simple_sampler',
                      'parameters': {'gain': 1.0, 'sampleId': '', 'bypass': false},
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
        case 'setDeviceStringParameter':
        case 'setMasterGain':
        case 'setPlayheadBeats':
        case 'play':
        case 'stop':
        case 'enterPlayMode':
        case 'allNotesOff':
        case 'clearCapture':
          return {'ok': true};
        case 'noteOn':
          final args = call.arguments as Map<dynamic, dynamic>?;
          lastNoteOnPitch = (args?['pitch'] as num?)?.toInt();
          lastNoteOnVelocity = (args?['velocity'] as num?)?.toDouble();
          return {'ok': true};
        case 'noteOff':
          return {'ok': true};
        case 'setModulation':
          lastModulation = (call.arguments as Map?)?['mod'] as double?;
          final v = lastModulation;
          if (v != null && (peakModulation == null || v > peakModulation!)) {
            peakModulation = v;
          }
          return {'ok': true};
        case 'setPitchBend':
          lastPitchBend = (call.arguments as Map?)?['bend'] as double?;
          final v = lastPitchBend;
          if (v != null && (peakPitchBend == null || v.abs() > peakPitchBend!.abs())) {
            peakPitchBend = v;
          }
          return {'ok': true};
        case 'setRecordArmed':
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'recordArmed': (call.arguments as Map?)?['armed'] == true,
              'selectedTrackId': 'track-1',
              'tracks': [
                {
                  'id': 'track-1',
                  'name': 'Track 1',
                  'devices': [
                    {
                      'id': 'dev-1',
                      'type': 'simple_sampler',
                      'parameters': {'gain': 1.0, 'sampleId': '', 'bypass': false},
                    },
                  ],
                  'midiClips': [],
                },
              ],
            },
          };
        case 'commitCapture':
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'recordArmed': true,
              'selectedTrackId': 'track-1',
              'tracks': [
                {
                  'id': 'track-1',
                  'name': 'Track 1',
                  'devices': [
                    {
                      'id': 'dev-1',
                      'type': 'simple_sampler',
                      'parameters': {'gain': 1.0, 'sampleId': '', 'bypass': false},
                    },
                  ],
                  'midiClips': [
                    {
                      'id': 'clip-cap',
                      'startBeat': 0.0,
                      'lengthBeats': 4.0,
                      'notes': [
                        {
                          'pitch': 48,
                          'startBeat': 0.0,
                          'durationBeats': 0.25,
                          'velocity': 100.0,
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          };
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

    expect(find.text('120'), findsOneWidget);
    expect(find.text('v0.1.0'), findsOneWidget);
    expect(find.bySemanticsLabel('Arrangement'), findsOneWidget);
    expect(find.bySemanticsLabel('Play'), findsOneWidget);
    expect(find.bySemanticsLabel('Mixer'), findsOneWidget);
    expect(find.bySemanticsLabel('Library'), findsOneWidget);
    expect(find.bySemanticsLabel('Project'), findsOneWidget);
    expect(find.textContaining('Engine:'), findsNothing);

    await tester.tap(find.byTooltip('Add track'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('Adding track shows no devices initially, can insert a device', (tester) async {
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

    expect(find.text('No devices'), findsOneWidget);
    expect(find.byType(DeviceInsertSlot), findsOneWidget);
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
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('Track 1'), findsOneWidget);
    expect(find.textContaining('bars'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('120'), findsOneWidget);
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

    await tester.tap(find.bySemanticsLabel('Project'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save project'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved project'), findsOneWidget);

    await tester.tap(find.text('Open project'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Loaded project'), findsOneWidget);
  });

  testWidgets('Play tab shows MPC pads after add track', (tester) async {
    mockWithSamplerDefault = true;
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
    await tester.tap(find.bySemanticsLabel('Play'));
    await tester.pumpAndSettle();

    expect(find.text('Pads'), findsOneWidget);
    expect(find.text('Perform'), findsOneWidget);
    expect(find.text('Oct 2'), findsOneWidget);
    expect(find.text('ARM'), findsOneWidget);
    expect(find.byType(MpcPadGrid), findsOneWidget);
    expect(find.text('SAMPLER'), findsNothing);
    expect(find.byTooltip('Track 1'), findsOneWidget);
  });

  testWidgets('Pad press invokes noteOn on bridge', (tester) async {
    mockWithSamplerDefault = true;
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
    await tester.tap(find.bySemanticsLabel('Play'));
    await tester.pumpAndSettle();

    final padGrid = tester.renderObject<RenderBox>(find.byType(MpcPadGrid));
    final topLeft = padGrid.localToGlobal(const Offset(8, 8));
    final gesture = await tester.startGesture(topLeft);
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 120));

    expect(lastNoteOnPitch, 48);
    expect(lastNoteOnVelocity, isNotNull);
  });

  testWidgets('Drag on pad sends pitchBend and modulation', (tester) async {
    mockWithSamplerDefault = true;
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
    await tester.tap(find.bySemanticsLabel('Play'));
    await tester.pumpAndSettle();

    final padGrid = tester.renderObject<RenderBox>(find.byType(MpcPadGrid));
    final topLeft = padGrid.localToGlobal(const Offset(8, 8));
    final gesture = await tester.startGesture(topLeft);
    await tester.pump(const Duration(milliseconds: 30));
    // Drag down (bend negative) and right (mod positive). 20px right
    // of the cell origin should map to mod ~ 20 / 60 = 0.33.
    await gesture.moveBy(const Offset(20, 15));
    await tester.pump(const Duration(milliseconds: 30));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 120));

    expect(peakModulation, isNotNull);
    expect(peakModulation, greaterThan(0.0));
    expect(peakPitchBend, isNotNull);
    expect(peakPitchBend, lessThan(0.0));
  });
}
