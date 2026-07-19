import 'dart:convert';

import 'package:audioapp/bridge/clip_snapshots.dart';
import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:audioapp/features/settings/audio_engine_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Device lab benchmark: cycle audio engine profiles while playing a workload.
///
/// Run from repo root (phone connected):
///   cd app_flutter
///   flutter test integration_test/audio_profile_lab_test.dart -d <serial>
///
/// Optional dart-defines:
///   LAB_SCENARIO=light|parallel|serial_chain|subtractive
///   LAB_PLAY_SECONDS=20
///   LAB_SETTLE_SECONDS=2
const _reportPrefix = '@@AUDIO_PROFILE_LAB@@';

Future<void> _setupLightWorkload(EngineBridge bridge) async {
  var snapshot = await bridge.createProject();
  snapshot = await bridge.addTrack(name: 'Lab Osc');
  final trackId = snapshot.tracks.last.id;
  await bridge.addDeviceToTrack(
    trackId: trackId,
    deviceType: 'simple_oscillator',
  );
  final clip = await bridge.createMidiClip(
    trackId: trackId,
    startBeat: 0,
    lengthBeats: 256,
  );
  final clipId = clip.tracks
      .firstWhere((track) => track.id == trackId)
      .midiClips
      .last
      .id;
  await bridge.setMidiClipNotes(
    clipId: clipId,
    notes: const [
      MidiNoteSnapshot(
        pitch: 60,
        startBeat: 0,
        durationBeats: 256,
        velocity: 100,
      ),
    ],
  );
}

Future<void> _setupParallelWorkload(EngineBridge bridge) async {
  await bridge.createProject();
  for (var index = 0; index < 4; index++) {
    var snapshot = await bridge.addTrack(name: 'Branch ${index + 1}');
    final trackId = snapshot.tracks.last.id;
    await bridge.addDeviceToTrack(
      trackId: trackId,
      deviceType: 'simple_oscillator',
    );
    final clip = await bridge.createMidiClip(
      trackId: trackId,
      startBeat: 0,
      lengthBeats: 256,
    );
    final clipId = clip.tracks
        .firstWhere((track) => track.id == trackId)
        .midiClips
        .last
        .id;
    await bridge.setMidiClipNotes(
      clipId: clipId,
      notes: [
        MidiNoteSnapshot(
          pitch: 60 + index * 2,
          startBeat: 0,
          durationBeats: 256,
          velocity: 100,
        ),
      ],
    );
  }
}

Future<void> _setupSerialChainWorkload(EngineBridge bridge) async {
  var snapshot = await bridge.createProject();
  snapshot = await bridge.addTrack(name: 'FX Chain');
  final trackId = snapshot.tracks.last.id;
  await bridge.addDeviceToTrack(
    trackId: trackId,
    deviceType: 'simple_oscillator',
  );
  for (final deviceType in ['distortion', 'filter', 'reverb']) {
    await bridge.addDeviceToTrack(trackId: trackId, deviceType: deviceType);
  }
  final clip = await bridge.createMidiClip(
    trackId: trackId,
    startBeat: 0,
    lengthBeats: 256,
  );
  final clipId = clip.tracks
      .firstWhere((track) => track.id == trackId)
      .midiClips
      .last
      .id;
  await bridge.setMidiClipNotes(
    clipId: clipId,
    notes: const [
      MidiNoteSnapshot(
        pitch: 60,
        startBeat: 0,
        durationBeats: 256,
        velocity: 100,
      ),
    ],
  );
}

Future<void> _setupSubtractiveWorkload(EngineBridge bridge) async {
  var snapshot = await bridge.createProject();
  snapshot = await bridge.addTrack(name: 'Subtractive');
  final trackId = snapshot.tracks.last.id;
  await bridge.addDeviceToTrack(
    trackId: trackId,
    deviceType: 'subtractive_synth',
  );
  final clip = await bridge.createMidiClip(
    trackId: trackId,
    startBeat: 0,
    lengthBeats: 256,
  );
  final clipId = clip.tracks
      .firstWhere((track) => track.id == trackId)
      .midiClips
      .last
      .id;
  await bridge.setMidiClipNotes(
    clipId: clipId,
    notes: const [
      MidiNoteSnapshot(
        pitch: 48,
        startBeat: 0,
        durationBeats: 1,
        velocity: 110,
      ),
      MidiNoteSnapshot(
        pitch: 52,
        startBeat: 1,
        durationBeats: 1,
        velocity: 105,
      ),
      MidiNoteSnapshot(
        pitch: 55,
        startBeat: 2,
        durationBeats: 1,
        velocity: 100,
      ),
      MidiNoteSnapshot(
        pitch: 60,
        startBeat: 3,
        durationBeats: 1,
        velocity: 100,
      ),
    ],
  );
}

Future<void> _setupScenario(EngineBridge bridge, String scenario) async {
  if (scenario == 'parallel') {
    await _setupParallelWorkload(bridge);
  } else if (scenario == 'serial_chain') {
    await _setupSerialChainWorkload(bridge);
  } else if (scenario == 'subtractive') {
    await _setupSubtractiveWorkload(bridge);
  } else {
    await _setupLightWorkload(bridge);
  }
}

double _deadlineMicros(AudioEngineStatus status) {
  if (status.sampleRate <= 0 || status.framesPerCallback <= 0) return 0;
  return status.framesPerCallback / status.sampleRate * 1e6;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('audio profile lab benchmark', () async {
    const scenario = String.fromEnvironment('LAB_SCENARIO', defaultValue: 'light');
    const playSeconds =
        int.fromEnvironment('LAB_PLAY_SECONDS', defaultValue: 20);
    const settleSeconds =
        int.fromEnvironment('LAB_SETTLE_SECONDS', defaultValue: 2);
    const sampleIntervalMs =
        int.fromEnvironment('LAB_SAMPLE_MS', defaultValue: 500);

    final bridge = EngineBridge();
    final ping = await bridge.ping();
    expect(ping, 'pong');

    await _setupScenario(bridge, scenario);

    final profiles = <AudioEngineProfile>[
      AudioEngineProfile.lowLatency,
      AudioEngineProfile.balanced,
      AudioEngineProfile.safe,
    ];
    const custom = AudioEngineCustomSettings();

    final startedAt = DateTime.now().toUtc().toIso8601String();
    final results = <Map<String, dynamic>>[];

    for (final profile in profiles) {
      final configured = await bridge.configureAudioEngine(profile, custom);
      await Future<void>.delayed(Duration(seconds: settleSeconds));

      await bridge.play();
      final playStarted = DateTime.now();
      final samples = <Map<String, dynamic>>[];

      while (DateTime.now().difference(playStarted).inSeconds < playSeconds) {
        await Future<void>.delayed(Duration(milliseconds: sampleIntervalMs));
        final status = await bridge.getAudioEngineStatus();
        final deadline = _deadlineMicros(status);
        samples.add({
          'elapsedMs': DateTime.now().difference(playStarted).inMilliseconds,
          'xRunCount': status.xRunCount,
          'callbackOverruns': status.callbackOverruns,
          'maxCallbackMicros': status.maxCallbackMicros,
          'deadlineMicros': deadline,
          'headroomMicros': deadline - status.maxCallbackMicros,
          'headroomRatio': deadline > 0
              ? (deadline - status.maxCallbackMicros) / deadline
              : 0.0,
        });
      }

      await bridge.stop();
      final finalStatus = await bridge.getAudioEngineStatus();
      final deadline = _deadlineMicros(finalStatus);

      results.add({
        'profile': profile.storageValue,
        'configured': {
          'sampleRate': configured.sampleRate,
          'framesPerCallback': configured.framesPerCallback,
          'bufferSizeFrames': configured.bufferSizeFrames,
          'bufferCapacityFrames': configured.bufferCapacityFrames,
          'framesPerBurst': configured.framesPerBurst,
          'performanceMode': configured.performanceMode,
          'sharingMode': configured.sharingMode,
        },
        'playSeconds': playSeconds,
        'samples': samples,
        'final': {
          'xRunCount': finalStatus.xRunCount,
          'callbackOverruns': finalStatus.callbackOverruns,
          'maxCallbackMicros': finalStatus.maxCallbackMicros,
          'deadlineMicros': deadline,
          'headroomMicros': deadline - finalStatus.maxCallbackMicros,
          'headroomRatio': deadline > 0
              ? (deadline - finalStatus.maxCallbackMicros) / deadline
              : 0.0,
          'streamOpen': finalStatus.streamOpen,
        },
      });
    }

    final report = {
      'kind': 'audio_profile_lab',
      'startedAt': startedAt,
      'finishedAt': DateTime.now().toUtc().toIso8601String(),
      'scenario': scenario,
      'playSeconds': playSeconds,
      'sampleIntervalMs': sampleIntervalMs,
      'results': results,
    };

    // Host-side scripts scrape this sentinel from flutter test output.
    print('$_reportPrefix${jsonEncode(report)}');
  });
}
