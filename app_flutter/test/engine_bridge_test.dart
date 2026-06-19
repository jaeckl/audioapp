import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/automation/automation_curve_shapes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.audioapp.daw/engine');
  final bridge = EngineBridge(channel: channel);

  const emptySnapshot = {
    'ok': true,
    'snapshot': {
      'bpm': 120,
      'playheadBeats': 0.0,
      'playing': false,
      'selectedTrackId': '',
      'tracks': [],
    },
  };

  const oneTrackSnapshot = {
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
              'type': 'track_gain',
              'parameters': {'gain': 1.0},
            },
          ],
          'midiClips': [],
        },
      ],
    },
  };

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'ping':
          return 'pong';
        case 'play':
        case 'stop':
          return null;
        case 'createProject':
          return emptySnapshot;
        case 'addTrack':
          return oneTrackSnapshot;
        case 'selectTrack':
          return oneTrackSnapshot;
        case 'setDeviceParameter':
        case 'setDeviceStringParameter':
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
                      'parameters': {'gain': 0.5, 'sampleId': 'sample-1'},
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
                      'parameters': {'gain': 1.0, 'sampleId': ''},
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
                      'parameters': {'gain': 1.0, 'sampleId': ''},
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
        case 'setClipLength':
          final args = call.arguments as Map<dynamic, dynamic>;
          final length = (args['lengthBeats'] as num).toDouble();
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
                      'parameters': {'gain': 1.0, 'sampleId': ''},
                    },
                  ],
                  'midiClips': [
                    {
                      'id': args['clipId'] as String? ?? 'clip-1',
                      'startBeat': 0.0,
                      'lengthBeats': length,
                      'notes': [
                        {
                          'pitch': 60,
                          'startBeat': 0.0,
                          'durationBeats': 4.0,
                          'velocity': 100.0,
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          };
        case 'createAutomationClip':
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
                      'type': 'subtractive_synth',
                      'parameters': {'gain': 1.0, 'filterCutoff': 1.0},
                    },
                  ],
                  'midiClips': [],
                  'automationClips': [
                    {
                      'id': 'aclip-1',
                      'startBeat': 0.0,
                      'lengthBeats': 4.0,
                      'deviceId': '',
                      'paramId': '',
                      'points': [
                        {'beat': 0.0, 'value': 1.0},
                        {'beat': 4.0, 'value': 0.25},
                      ],
                    },
                  ],
                },
              ],
            },
          };
        case 'assignAutomationTarget':
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
                      'type': 'subtractive_synth',
                      'parameters': {'gain': 1.0, 'filterCutoff': 1.0},
                    },
                  ],
                  'midiClips': [],
                  'automationClips': [
                    {
                      'id': 'aclip-1',
                      'startBeat': 0.0,
                      'lengthBeats': 4.0,
                      'deviceId': 'dev-1',
                      'paramId': 'filterCutoff',
                      'points': [
                        {'beat': 0.0, 'value': 1.0},
                        {'beat': 4.0, 'value': 0.25},
                      ],
                    },
                  ],
                },
              ],
            },
          };
        case 'setAutomationPoints':
          final args = call.arguments as Map<dynamic, dynamic>;
          final points = args['points'] as List<dynamic>? ?? [];
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
                      'type': 'subtractive_synth',
                      'parameters': {'gain': 1.0, 'filterCutoff': 1.0},
                    },
                  ],
                  'midiClips': [],
                  'automationClips': [
                    {
                      'id': args['clipId'] as String? ?? 'aclip-1',
                      'startBeat': 0.0,
                      'lengthBeats': 4.0,
                      'deviceId': 'dev-1',
                      'paramId': 'filterCutoff',
                      'points': points,
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
                      'type': 'simple_sampler',
                      'parameters': {'gain': 0.5, 'sampleId': ''},
                    },
                  ],
                  'midiClips': [],
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

  test('ping returns pong', () async {
    expect(await bridge.ping(), 'pong');
  });

  test('play and stop dispatch bridge commands', () async {
    await bridge.play();
    await bridge.stop();
  });

  test('addTrack returns snapshot with track', () async {
    final snapshot = await bridge.addTrack(name: 'Track 1');
    expect(snapshot.tracks.length, 1);
    expect(snapshot.tracks.first.devices.first.gain, 1.0);
  });

  test('setDeviceParameter updates sampler gain in snapshot', () async {
    final snapshot = await bridge.setDeviceParameter(
      deviceId: 'dev-1',
      parameterId: 'gain',
      value: 0.5,
    );
    expect(snapshot.selectedTrack?.devices.first.gain, 0.5);
  });

  test('setDeviceStringParameter updates sampler sample id', () async {
    final snapshot = await bridge.setDeviceStringParameter(
      deviceId: 'dev-1',
      parameterId: 'sampleId',
      value: 'sample-1',
    );
    expect(snapshot.selectedTrack?.devices.first.sampleId, 'sample-1');
  });

  test('createMidiClip returns snapshot with clip', () async {
    await bridge.addTrack(name: 'Track 1');
    final snapshot = await bridge.createMidiClip(trackId: 'track-1');
    expect(snapshot.selectedTrack?.midiClips.length, 1);
    expect(snapshot.selectedTrack?.midiClips.first.lengthBeats, 4.0);
  });

  test('setMidiClipNotes updates notes in snapshot', () async {
    await bridge.addTrack(name: 'Track 1');
    await bridge.createMidiClip(trackId: 'track-1');
    final snapshot = await bridge.setMidiClipNotes(
      clipId: 'clip-1',
      notes: const [
        MidiNoteSnapshot(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
        MidiNoteSnapshot(pitch: 64, startBeat: 1, durationBeats: 1, velocity: 100),
      ],
    );
    expect(snapshot.selectedTrack?.midiClips.first.notes.length, 2);
    expect(snapshot.selectedTrack?.midiClips.first.notes[1].pitch, 64);
  });

  test('setClipLength updates clip length in snapshot', () async {
    await bridge.addTrack(name: 'Track 1');
    await bridge.createMidiClip(trackId: 'track-1');
    final snapshot = await bridge.setClipLength(clipId: 'clip-1', lengthBeats: 2.0);
    expect(snapshot.selectedTrack?.midiClips.first.lengthBeats, 2.0);
    expect(snapshot.selectedTrack?.midiClips.first.notes.length, 1);
    expect(snapshot.selectedTrack?.midiClips.first.kind, ClipContentKind.midi);
  });

  test('saveProject returns uri', () async {
    final uri = await bridge.saveProject();
    expect(uri, 'file:///tmp/project.audioapp.zip');
  });

  test('loadProject returns snapshot', () async {
    final snapshot = await bridge.loadProject();
    expect(snapshot, isNotNull);
    expect(snapshot!.tracks.first.name, 'Loaded Track');
    expect(snapshot.tracks.first.devices.first.gain, 0.5);
  });

  test('createAutomationClip returns automation clip on track', () async {
    await bridge.addTrack(name: 'Track 1');
    final snapshot = await bridge.createAutomationClip(trackId: 'track-1');
    final clips = snapshot.selectedTrack?.automationClips ?? [];
    expect(clips.length, 1);
    expect(clips.first.lengthBeats, 4.0);
    expect(clips.first.isLinked, isFalse);
  });

  test('assignAutomationTarget links clip to device param', () async {
    await bridge.addTrack(name: 'Track 1');
    await bridge.createAutomationClip(trackId: 'track-1');
    final snapshot = await bridge.assignAutomationTarget(
      clipId: 'aclip-1',
      deviceId: 'dev-1',
      paramId: 'filterCutoff',
    );
    final clip = snapshot.selectedTrack!.automationClips.first;
    expect(clip.isLinked, isTrue);
    expect(clip.deviceId, 'dev-1');
    expect(clip.paramId, 'filterCutoff');
  });

  test('setAutomationPoints updates curve breakpoints', () async {
    await bridge.addTrack(name: 'Track 1');
    await bridge.createAutomationClip(trackId: 'track-1');
    final snapshot = await bridge.setAutomationPoints(
      clipId: 'aclip-1',
      points: const [
        AutomationPointSnapshot(beat: 0, value: 0.8),
        AutomationPointSnapshot(beat: 2, value: 0.2),
      ],
    );
    expect(snapshot.selectedTrack!.automationClips.first.points.length, 2);
    expect(snapshot.selectedTrack!.automationClips.first.points.last.value, 0.2);
  });

  test('setAutomationPoints round-trips dense saw breakpoints', () async {
    await bridge.addTrack(name: 'Track 1');
    await bridge.createAutomationClip(trackId: 'track-1');
    final sawPoints = generateAutomationShapePoints(
      shape: AutomationCurveShape.sawUp,
      params: const AutomationShapeParams(cycles: 4),
      lengthBeats: 4,
    );
    expect(sawPoints.length, greaterThan(2));

    final snapshot = await bridge.setAutomationPoints(
      clipId: 'aclip-1',
      points: sawPoints,
    );
    expect(
      snapshot.selectedTrack!.automationClips.first.points.length,
      sawPoints.length,
    );
  });
}
