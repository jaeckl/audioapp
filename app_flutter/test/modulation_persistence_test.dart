import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.audioapp.daw/engine');
  final bridge = EngineBridge(channel: channel);

  // Stateful data that simulates the engine's project state through save/load.
  Map<String, dynamic>? savedState;
  Map<String, dynamic> currentSnapshot = _initialSnapshot();

  setUp(() {
    currentSnapshot = _initialSnapshot();
    savedState = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'createLfo':
          final lfos = List<Map<String, dynamic>>.from(
            currentSnapshot['lfos'] as List,
          );
          final newId = lfos.isEmpty ? 1 : (lfos.last['id'] as int) + 1;
          lfos.add({
            'id': newId,
            'modulatorType': 0,
            'retrigger': 1,
            'waveform': 0,
            'rate': 1.0,
            'syncDivision': 3,
            'phase': 0.0,
            'polarity': 0,
            'attack': 0.1,
            'decay': 0.25,
            'sustain': 0.7,
            'release': 0.35,
            'name': '',
          });
          currentSnapshot['lfos'] = lfos;
          return {
            'ok': true,
            'snapshot': Map<String, dynamic>.from(currentSnapshot),
          };

        case 'assignModulation':
          final args = call.arguments as Map<dynamic, dynamic>;
          final edges = List<Map<String, dynamic>>.from(
            currentSnapshot['modEdges'] as List,
          );
          edges.add({
            'lfoId': (args['lfoId'] as num).toInt(),
            'deviceId': args['deviceId'] as String,
            'paramId': args['paramId'] as String,
            'amount': (args['amount'] as num).toDouble(),
          });
          currentSnapshot['modEdges'] = edges;
          return {
            'ok': true,
            'snapshot': Map<String, dynamic>.from(currentSnapshot),
          };

        case 'removeModulation':
          final args = call.arguments as Map<dynamic, dynamic>;
          final lfoId = (args['lfoId'] as num).toInt();
          final paramId = args['paramId'] as String;
          final edges = List<Map<String, dynamic>>.from(
            currentSnapshot['modEdges'] as List,
          );
          edges.removeWhere(
            (e) => e['lfoId'] == lfoId && e['paramId'] == paramId,
          );
          currentSnapshot['modEdges'] = edges;
          return {
            'ok': true,
            'snapshot': Map<String, dynamic>.from(currentSnapshot),
          };

        case 'removeLfo':
          final args = call.arguments as Map<dynamic, dynamic>;
          final lfoId = (args['lfoId'] as num).toInt();
          // Remove the LFO
          final lfos = List<Map<String, dynamic>>.from(
            currentSnapshot['lfos'] as List,
          );
          lfos.removeWhere((l) => l['id'] == lfoId);
          currentSnapshot['lfos'] = lfos;
          // Also remove any modulation edges that reference this LFO
          final edges = List<Map<String, dynamic>>.from(
            currentSnapshot['modEdges'] as List,
          );
          edges.removeWhere((e) => e['lfoId'] == lfoId);
          currentSnapshot['modEdges'] = edges;
          return {
            'ok': true,
            'snapshot': Map<String, dynamic>.from(currentSnapshot),
          };

        case 'saveProject':
          savedState = Map<String, dynamic>.from(currentSnapshot);
          return {
            'ok': true,
            'uri': 'file:///tmp/test.audioapp.zip',
            'cancelled': false,
          };

        case 'loadProject':
          if (savedState != null) {
            currentSnapshot = Map<String, dynamic>.from(savedState!);
          }
          return {
            'ok': true,
            'snapshot': Map<String, dynamic>.from(currentSnapshot),
          };

        case 'createProject':
          currentSnapshot = _initialSnapshot();
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

  test('LFO persists through save/load', () async {
    final afterCreate = await bridge.createLfo(modulatorType: 0);
    expect(afterCreate.lfos.length, 1);
    expect(afterCreate.lfos.first.id, 1);

    final savedUri = await bridge.saveProject();
    expect(savedUri, isNotNull);

    final loaded = await bridge.loadProject();
    expect(loaded, isNotNull);
    expect(loaded!.lfos.length, 1);
    expect(loaded.lfos.first.id, 1);
    expect(loaded.lfos.first.waveform, 0);
    expect(loaded.lfos.first.rate, 1.0);
  });

  test('LFO + modulation edge persist through save/load', () async {
    await bridge.createLfo(modulatorType: 0);
    final afterAssign = await bridge.assignModulation(
      lfoId: 1,
      deviceId: 'dev-1',
      paramId: 'filterCutoff',
      amount: 0.5,
    );
    expect(afterAssign.modEdges.length, 1);
    expect(afterAssign.modEdges.first.lfoId, 1);
    expect(afterAssign.modEdges.first.amount, 0.5);

    final savedUri = await bridge.saveProject();
    expect(savedUri, isNotNull);

    final loaded = await bridge.loadProject();
    expect(loaded, isNotNull);
    expect(loaded!.lfos.length, 1);
    expect(loaded.lfos.first.id, 1);
    expect(loaded.modEdges.length, 1);
    expect(loaded.modEdges.first.lfoId, 1);
    expect(loaded.modEdges.first.deviceId, 'dev-1');
    expect(loaded.modEdges.first.paramId, 'filterCutoff');
    expect(loaded.modEdges.first.amount, 0.5);
  });

  test('Multiple LFOs and edges survive save/load', () async {
    // Create first LFO and assign modulation
    await bridge.createLfo(modulatorType: 0);
    await bridge.assignModulation(
      lfoId: 1,
      deviceId: 'dev-1',
      paramId: 'filterCutoff',
      amount: 0.5,
    );

    // Create second LFO and assign modulation
    await bridge.createLfo(modulatorType: 0);
    await bridge.assignModulation(
      lfoId: 2,
      deviceId: 'dev-1',
      paramId: 'gain',
      amount: -0.3,
    );

    final loaded1 = await bridge.loadProject(); // just refreshes local state
    expect(loaded1, isNotNull);

    final savedUri = await bridge.saveProject();
    expect(savedUri, isNotNull);

    final loaded = await bridge.loadProject();
    expect(loaded, isNotNull);
    expect(loaded!.lfos.length, 2);
    expect(loaded.lfos[0].id, 1);
    expect(loaded.lfos[1].id, 2);
    expect(loaded.modEdges.length, 2);
    expect(loaded.modEdges[0].lfoId, 1);
    expect(loaded.modEdges[0].amount, 0.5);
    expect(loaded.modEdges[1].lfoId, 2);
    expect(loaded.modEdges[1].amount, -0.3);
  });

  test('Removing LFO before save means it is absent after load', () async {
    // Create two LFOs
    await bridge.createLfo(modulatorType: 0);
    await bridge.createLfo(modulatorType: 0);
    // Assign modulation from first LFO
    await bridge.assignModulation(
      lfoId: 1,
      deviceId: 'dev-1',
      paramId: 'filterCutoff',
      amount: 0.5,
    );
    // Remove the first LFO
    final afterRemove = await bridge.removeLfo(1);
    expect(afterRemove.lfos.length, 1);
    expect(afterRemove.lfos.first.id, 2);
    // Modulation edge should also be gone
    expect(afterRemove.modEdges.length, 0);

    final savedUri = await bridge.saveProject();
    expect(savedUri, isNotNull);

    final loaded = await bridge.loadProject();
    expect(loaded, isNotNull);
    expect(loaded!.lfos.length, 1);
    expect(loaded.lfos.first.id, 2);
    expect(loaded.modEdges.length, 0);
  });

  test('Removing modulation edge before save means it is absent after load',
      () async {
    await bridge.createLfo(modulatorType: 0);
    await bridge.assignModulation(
      lfoId: 1,
      deviceId: 'dev-1',
      paramId: 'filterCutoff',
      amount: 0.5,
    );
    // Remove the modulation edge
    final afterRemove = await bridge.removeModulation(
      lfoId: 1,
      paramId: 'filterCutoff',
    );
    expect(afterRemove.lfos.length, 1);
    expect(afterRemove.modEdges.length, 0);

    final savedUri = await bridge.saveProject();
    expect(savedUri, isNotNull);

    final loaded = await bridge.loadProject();
    expect(loaded, isNotNull);
    expect(loaded!.lfos.length, 1);
    expect(loaded.modEdges.length, 0);
  });
}

/// Returns the initial project snapshot map with a subtractive synth and empty
/// LFO / modulation arrays.
Map<String, dynamic> _initialSnapshot() {
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
            'type': 'subtractive_synth',
            'parameters': {'gain': 1.0, 'filterCutoff': 1.0},
          },
        ],
        'midiClips': [],
        'sampleClips': [],
      },
    ],
    'samples': [],
    'lfos': <Map<String, dynamic>>[],
    'modEdges': <Map<String, dynamic>>[],
  };
}