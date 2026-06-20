import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.audioapp.daw/engine');
  final bridge = EngineBridge(channel: channel);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'createLfo':
          final args = call.arguments as Map<dynamic, dynamic>? ?? {};
          final modulatorType =
              (args['modulatorType'] as num?)?.toInt() ?? 0;
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'selectedTrackId': '',
              'tracks': [],
              'lfos': [
                {
                  'id': 1,
                  'modulatorType': modulatorType,
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
                },
              ],
              'modEdges': [],
            },
          };
        case 'removeLfo':
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'selectedTrackId': '',
              'tracks': [],
              'lfos': [],
              'modEdges': [],
            },
          };
        case 'updateLfoParam':
          final args = call.arguments as Map<dynamic, dynamic>;
          final param = args['param'] as String? ?? '';
          final value = (args['value'] as num?)?.toDouble() ?? 0.0;
          final lfoId = (args['lfoId'] as num?)?.toInt() ?? 0;
          final updatedLfo = <String, dynamic>{
            'id': lfoId,
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
          };
          if (param == 'rate') {
            updatedLfo['rate'] = value;
          } else if (param == 'waveform') {
            updatedLfo['waveform'] = value.toInt();
          } else if (param == 'syncDivision') {
            updatedLfo['syncDivision'] = value.toInt();
          } else if (param == 'retrigger') {
            updatedLfo['retrigger'] = value.toInt();
          } else if (param == 'polarity') {
            updatedLfo['polarity'] = value.toInt();
          } else if (param == 'phase') {
            updatedLfo['phase'] = value;
          }
          return {
            'ok': true,
            'snapshot': {
              'bpm': 120,
              'playheadBeats': 0.0,
              'playing': false,
              'selectedTrackId': '',
              'tracks': [],
              'lfos': [updatedLfo],
              'modEdges': [],
            },
          };
        case 'assignModulation':
          final args = call.arguments as Map<dynamic, dynamic>;
          final lfoId = (args['lfoId'] as num?)?.toInt() ?? 0;
          final deviceId = args['deviceId'] as String? ?? '';
          final paramId = args['paramId'] as String? ?? '';
          final amount = (args['amount'] as num?)?.toDouble() ?? 0.0;
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
                      'id': deviceId,
                      'type': 'subtractive_synth',
                      'parameters': {'gain': 1.0, 'filterCutoff': 1.0},
                    },
                  ],
                  'midiClips': [],
                },
              ],
              'lfos': [
                {
                  'id': lfoId,
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
                },
              ],
              'modEdges': [
                {
                  'lfoId': lfoId,
                  'deviceId': deviceId,
                  'paramId': paramId,
                  'amount': amount,
                },
              ],
            },
          };
        case 'removeModulation':
          final args = call.arguments as Map<dynamic, dynamic>;
          final remLfoId = (args['lfoId'] as num?)?.toInt() ?? 0;
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
                },
              ],
              'lfos': [
                {
                  'id': remLfoId,
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
                },
              ],
              'modEdges': [],
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

  test('createLfo adds LFO to snapshot', () async {
    final result = await bridge.createLfo(modulatorType: 0);
    expect(result.lfos.length, greaterThan(0));
    expect(result.lfos.first.id, 1);
    expect(result.lfos.first.modulatorType, 0);
  });

  test('removeLfo removes LFO from snapshot', () async {
    final result = await bridge.removeLfo(1);
    expect(result.lfos, isEmpty);
  });

  test('updateLfoParam updates rate on snapshot', () async {
    final result =
        await bridge.updateLfoParam(lfoId: 1, param: 'rate', value: 2.0);
    expect(result.lfos.length, greaterThan(0));
    expect(result.lfos.first.rate, 2.0);
  });

  test('updateLfoParam updates waveform on snapshot', () async {
    final result =
        await bridge.updateLfoParam(lfoId: 1, param: 'waveform', value: 3);
    expect(result.lfos.length, greaterThan(0));
    expect(result.lfos.first.waveform, 3);
  });

  test('assignModulation adds edge to snapshot', () async {
    final result = await bridge.assignModulation(
      lfoId: 1,
      deviceId: 'dev-1',
      paramId: 'filterCutoff',
      amount: 0.75,
    );
    expect(result.modEdges.length, greaterThan(0));
    expect(result.modEdges.first.lfoId, 1);
    expect(result.modEdges.first.deviceId, 'dev-1');
    expect(result.modEdges.first.paramId, 'filterCutoff');
    expect(result.modEdges.first.amount, 0.75);
  });

  test('removeModulation removes edge from snapshot', () async {
    final result = await bridge.removeModulation(
      lfoId: 1,
      paramId: 'filterCutoff',
    );
    expect(result.modEdges, isEmpty);
  });

  test('createLfo with different modulatorType values', () async {
    final lfo0 = await bridge.createLfo(modulatorType: 0);
    expect(lfo0.lfos.first.modulatorType, 0);

    final lfo1 = await bridge.createLfo(modulatorType: 1);
    expect(lfo1.lfos.first.modulatorType, 1);

    final lfo2 = await bridge.createLfo(modulatorType: 2);
    expect(lfo2.lfos.first.modulatorType, 2);
  });
}