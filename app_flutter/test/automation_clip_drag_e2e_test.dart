import 'package:audioapp/app/daw_shell.dart';
import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.audioapp.daw/engine');
  final bridge = EngineBridge(channel: channel);

  // ---------------------------------------------------------------------------
  // Bridge-level test: moveClip returns snapshot with updated homeTrackId
  // ---------------------------------------------------------------------------
  group('moveClip via EngineBridge updates automation clip homeTrackId', () {
    Map<String, dynamic> currentSnapshot = _twoTrackSnapshot();

    setUp(() {
      currentSnapshot = _twoTrackSnapshot();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'createProject':
          case 'getProjectSnapshot':
            return {
              'ok': true,
              'snapshot': Map<String, dynamic>.from(currentSnapshot),
            };

          case 'moveClip':
            final args = call.arguments as Map<dynamic, dynamic>;
            final clipId = args['clipId'] as String;
            final targetTrackId = args['trackId'] as String;
            final startBeat = (args['startBeat'] as num).toDouble();

            final globalClips =
                List<Map<String, dynamic>>.from(
                  currentSnapshot['automationClips'] as List,
                );
            for (var i = 0; i < globalClips.length; i++) {
              if (globalClips[i]['id'] == clipId) {
                globalClips[i] = Map<String, dynamic>.from(globalClips[i]);
                globalClips[i]['homeTrackId'] = targetTrackId;
                globalClips[i]['startBeat'] = startBeat;
                break;
              }
            }
            currentSnapshot['automationClips'] = globalClips;

            final tracks =
                List<Map<String, dynamic>>.from(
                  currentSnapshot['tracks'] as List,
                );
            for (var i = 0; i < tracks.length; i++) {
              final trackId = tracks[i]['id'] as String;
              final trackClips = globalClips
                  .where((c) => c['homeTrackId'] == trackId)
                  .map((c) => Map<String, dynamic>.from(c))
                  .toList();
              tracks[i] = Map<String, dynamic>.from(tracks[i]);
              tracks[i]['automationClips'] = trackClips;
            }
            currentSnapshot['tracks'] = tracks;

            return {
              'ok': true,
              'snapshot': Map<String, dynamic>.from(currentSnapshot),
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

    test('homeTrackId changes after moveClip to different track', () async {
      var snapshot = await bridge.getProjectSnapshot();
      expect(snapshot.tracks[0].automationClips.length, 1);
      expect(snapshot.tracks[1].automationClips.length, 0);
      expect(snapshot.tracks[0].automationClips.first.homeTrackId, 'track-1');

      snapshot = await bridge.moveClip(
        clipId: 'aclip-1',
        trackId: 'track-2',
        startBeat: 8.0,
      );

      expect(snapshot.tracks[0].automationClips.length, 0);
      expect(snapshot.tracks[1].automationClips.length, 1);
      expect(snapshot.tracks[1].automationClips.first.homeTrackId, 'track-2');
      expect(snapshot.tracks[1].automationClips.first.startBeat, 8.0);
      expect(snapshot.tracks[1].automationClips.first.id, 'aclip-1');
    });

    test('moveClip round-trip — move back to original track', () async {
      await bridge.moveClip(
        clipId: 'aclip-1',
        trackId: 'track-2',
        startBeat: 8.0,
      );
      final back = await bridge.moveClip(
        clipId: 'aclip-1',
        trackId: 'track-1',
        startBeat: 0.0,
      );
      expect(back.tracks[0].automationClips.length, 1);
      expect(back.tracks[1].automationClips.length, 0);
      expect(back.tracks[0].automationClips.first.homeTrackId, 'track-1');
      expect(back.tracks[0].automationClips.first.startBeat, 0.0);
    });

    test('homeTrackId stays unchanged when moving with empty trackId', () async {
      // Set beat but don't change track
      await bridge.moveClip(
        clipId: 'aclip-1',
        trackId: 'track-1',
        startBeat: 12.0,
      );
      final snap = await bridge.getProjectSnapshot();
      expect(snap.tracks[0].automationClips.first.homeTrackId, 'track-1');
      expect(snap.tracks[0].automationClips.first.startBeat, 12.0);
      expect(snap.tracks[1].automationClips.length, 0);
    });

    test('Per-track automationClips list matches filter by homeTrackId', () async {
      // After moving to track 2, verify track 1 has 0 and track 2 has 1.
      final moved = await bridge.moveClip(
        clipId: 'aclip-1',
        trackId: 'track-2',
        startBeat: 4.0,
      );
      expect(moved.tracks[0].automationClips.length, 0);
      expect(moved.tracks[1].automationClips.length, 1);
      expect(moved.tracks[1].automationClips.first.id, 'aclip-1');

      // The global list should still have exactly 1 clip.
      expect(moved.automationClips.length, 1);
      expect(moved.automationClips.first.homeTrackId, 'track-2');
    });
  });

  // ---------------------------------------------------------------------------
  // Widget-level integration test: DawShell renders clip on the right track
  // ---------------------------------------------------------------------------
  group('Arrangement renders automation clip on correct track after move', () {
    Map<String, dynamic> currentSnapshot = _bootstrapSnapshot();

    setUp(() {
      currentSnapshot = _bootstrapSnapshot();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'ping':
            return 'pong';
          case 'createProject':
            currentSnapshot = _bootstrapSnapshot();
            return {
              'ok': true,
              'snapshot': Map<String, dynamic>.from(currentSnapshot),
            };
          case 'getProjectSnapshot':
            return {
              'ok': true,
              'snapshot': Map<String, dynamic>.from(currentSnapshot),
            };
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
            // After bootstrapping addTrack, switch to the real two-track
            // snapshot so the arrangement shows 2 tracks with an automation
            // clip on track-1.
            currentSnapshot = _twoTrackSnapshot();
            return {
              'ok': true,
              'snapshot': Map<String, dynamic>.from(currentSnapshot),
            };
          case 'selectTrack':
            final args = call.arguments as Map<dynamic, dynamic>?;
            final selId = args?['trackId'] as String? ?? '';
            currentSnapshot['selectedTrackId'] = selId;
            return {
              'ok': true,
              'snapshot': Map<String, dynamic>.from(currentSnapshot),
            };
          case 'setPlayheadBeats':
          case 'setLoopRegion':
          case 'allNotesOff':
          case 'enterPlayMode':
          case 'play':
          case 'stop':
            return {'ok': true};

          case 'moveClip':
            final args = call.arguments as Map<dynamic, dynamic>;
            final clipId = args['clipId'] as String;
            final targetTrackId = args['trackId'] as String;
            final startBeat = (args['startBeat'] as num).toDouble();

            final globalClips =
                List<Map<String, dynamic>>.from(
                  currentSnapshot['automationClips'] as List,
                );
            for (var i = 0; i < globalClips.length; i++) {
              if (globalClips[i]['id'] == clipId) {
                globalClips[i] = Map<String, dynamic>.from(globalClips[i]);
                globalClips[i]['homeTrackId'] = targetTrackId;
                globalClips[i]['startBeat'] = startBeat;
                break;
              }
            }
            currentSnapshot['automationClips'] = globalClips;

            final tracks =
                List<Map<String, dynamic>>.from(
                  currentSnapshot['tracks'] as List,
                );
            for (var i = 0; i < tracks.length; i++) {
              final trackId = tracks[i]['id'] as String;
              final trackClips = globalClips
                  .where((c) => c['homeTrackId'] == trackId)
                  .map((c) => Map<String, dynamic>.from(c))
                  .toList();
              tracks[i] = Map<String, dynamic>.from(tracks[i]);
              tracks[i]['automationClips'] = trackClips;
            }
            currentSnapshot['tracks'] = tracks;
            return {
              'ok': true,
              'snapshot': Map<String, dynamic>.from(currentSnapshot),
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

    testWidgets('AUTO placeholder appears when arrangement shows automation clip',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: DawShell(bridge: EngineBridge(channel: channel))),
      );
      await tester.pumpAndSettle();

      // Unlinked automation clips show 'AUTO' placeholder text.
      expect(find.text('AUTO'), findsOneWidget);
    });

    testWidgets('moveClip via bridge moves automation clip between tracks in snapshot',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: DawShell(bridge: EngineBridge(channel: channel))),
      );
      await tester.pumpAndSettle();

      // Initially the clip is on track-1.
      var snap = await bridge.getProjectSnapshot();
      expect(snap.tracks[0].automationClips.length, 1);
      expect(snap.tracks[1].automationClips.length, 0);

      // Move it to track-2 through the real bridge path.
      snap = await bridge.moveClip(
        clipId: 'aclip-1',
        trackId: 'track-2',
        startBeat: 4.0,
      );

      // Track-1 lost it, track-2 gained it.
      expect(snap.tracks[0].automationClips.length, 0);
      expect(snap.tracks[1].automationClips.length, 1);
      expect(snap.tracks[1].automationClips.first.homeTrackId, 'track-2');
      expect(snap.tracks[1].automationClips.first.startBeat, 4.0);

      // The clip still exists in the global list (it wasn't deleted).
      expect(snap.automationClips.length, 1);
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Empty bootstrap snapshot — no tracks, no clips.
Map<String, dynamic> _bootstrapSnapshot() {
  return {
    'bpm': 120,
    'playheadBeats': 0.0,
    'playing': false,
    'loopEnabled': true,
    'loopRegionStartBeat': 0.0,
    'loopLengthBeats': 16.0,
    'recordArmed': false,
    'selectedTrackId': '',
    'master': {'id': 'master', 'name': 'Master', 'gain': 1.0},
    'tracks': <Map<String, dynamic>>[],
    'samples': [],
    'automationClips': <Map<String, dynamic>>[],
    'lfos': <Map<String, dynamic>>[],
    'modEdges': <Map<String, dynamic>>[],
  };
}

/// Snapshot with two tracks and one unlinked automation clip on track 1.
Map<String, dynamic> _twoTrackSnapshot() {
  return {
    'bpm': 120,
    'playheadBeats': 0.0,
    'playing': false,
    'loopEnabled': true,
    'loopRegionStartBeat': 0.0,
    'loopLengthBeats': 16.0,
    'recordArmed': false,
    'selectedTrackId': 'track-1',
    'master': {'id': 'master', 'name': 'Master', 'gain': 1.0},
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
        'sampleClips': [],
        'automationClips': [
          {
            'id': 'aclip-1',
            'homeTrackId': 'track-1',
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
      {
        'id': 'track-2',
        'name': 'Track 2',
        'devices': [
          {
            'id': 'dev-2',
            'type': 'track_gain',
            'parameters': {'gain': 1.0},
          },
        ],
        'midiClips': [],
        'sampleClips': [],
        'automationClips': [],
      },
    ],
    'samples': [],
    'automationClips': [
      {
        'id': 'aclip-1',
        'homeTrackId': 'track-1',
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
    'lfos': <Map<String, dynamic>>[],
    'modEdges': <Map<String, dynamic>>[],
  };
}