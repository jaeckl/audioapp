import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
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
              'type': 'simple_oscillator',
              'parameters': {'frequency': 440.0},
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
                      'parameters': {'frequency': 220.0},
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
                      'type': 'simple_oscillator',
                      'parameters': {'frequency': 440.0},
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
    expect(snapshot.tracks.first.devices.first.frequencyHz, 440.0);
  });

  test('setDeviceParameter updates frequency in snapshot', () async {
    final snapshot = await bridge.setDeviceParameter(
      deviceId: 'dev-1',
      parameterId: 'frequency',
      value: 220.0,
    );
    expect(snapshot.selectedTrack?.devices.first.frequencyHz, 220.0);
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

  test('saveProject returns uri', () async {
    final uri = await bridge.saveProject();
    expect(uri, 'file:///tmp/project.audioapp.zip');
  });

  test('loadProject returns snapshot', () async {
    final snapshot = await bridge.loadProject();
    expect(snapshot, isNotNull);
    expect(snapshot!.tracks.first.name, 'Loaded Track');
    expect(snapshot.tracks.first.devices.first.frequencyHz, 220.0);
  });
}
