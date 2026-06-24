import 'package:flutter_test/flutter_test.dart';
import 'package:audioapp/bridge/project_snapshot.dart';

void main() {
  group('LfoSnapshot.fromMap', () {
    test('parses LFO fields from type-dispatch JSON', () {
      // Engine JSON map: new style with type="lfo"
      const map = <dynamic, dynamic>{
        'id': 7,
        'type': 'lfo',
        'retrigger': 1,
        'waveform': 3,
        'rate': 2.5,
        'syncDivision': 4,
        'phase': 0.25,
        'polarity': 1,
        'attack': 0.05,
        'decay': 0.3,
        'sustain': 0.8,
        'release': 0.4,
        'morph': 0.75,
        'spread': 0.3,
        'analogMode': 1,
      };
      final lfo = LfoSnapshot.fromMap(map);

      expect(lfo.id, 7);
      expect(lfo.type, 'lfo');
      expect(lfo.retrigger, 1);
      expect(lfo.waveform, 3);
      expect(lfo.rate, 2.5);
      expect(lfo.syncDivision, 4);
      expect(lfo.phase, 0.25);
      expect(lfo.polarity, 1);
      expect(lfo.attack, 0.05);
      expect(lfo.decay, 0.3);
      expect(lfo.sustain, 0.8);
      expect(lfo.release, 0.4);
      expect(lfo.morph, 0.75);
      expect(lfo.spread, 0.3);
      expect(lfo.analogMode, 1);
    });

    test('parses envelope fields from type-dispatch JSON', () {
      // Engine JSON: envelope type
      const map = <dynamic, dynamic>{
        'id': 3,
        'type': 'envelope',
        'curveType': 2,
        'attack': 0.01,
        'hold': 0.1,
        'decay': 0.3,
        'sustain': 0.5,
        'release': 1.2,
        'delay': 0.15,
        'attackCurve': 0.3,
        'decayCurve': 0.7,
        'releaseCurve': 0.2,
      };
      final lfo = LfoSnapshot.fromMap(map);

      expect(lfo.id, 3);
      expect(lfo.type, 'envelope');
      expect(lfo.curveType, 2);
      expect(lfo.attack, 0.01);
      expect(lfo.hold, 0.1);
      expect(lfo.decay, 0.3);
      expect(lfo.sustain, 0.5);
      expect(lfo.release, 1.2);
      expect(lfo.delay, 0.15);
      expect(lfo.attackCurve, 0.3);
      expect(lfo.decayCurve, 0.7);
      expect(lfo.releaseCurve, 0.2);
      expect(lfo.analogMode, 0);
      expect(lfo.polarity, 0); // envelope polarity always defaults to 0
    });

    test('handles missing fields with constructor defaults', () {
      final lfo = LfoSnapshot.fromMap(<dynamic, dynamic>{});
      expect(lfo.id, 0);
      expect(lfo.type, 'lfo');
      expect(lfo.retrigger, 0);
      expect(lfo.waveform, 0);
      expect(lfo.rate, 1.0);
      expect(lfo.syncDivision, 0);
      expect(lfo.phase, 0.0);
      expect(lfo.polarity, 0);
      expect(lfo.attack, 0.1);
      expect(lfo.decay, 0.25);
      expect(lfo.sustain, 0.7);
      expect(lfo.release, 0.35);
      expect(lfo.morph, 0.0);
      expect(lfo.spread, 0.5);
    });
  });

  group('ModulationEdgeSnapshot.fromMap', () {
    test('parses all 4 fields', () {
      const map = <dynamic, dynamic>{
        'lfoId': 1,
        'deviceId': 'dev-osc-1',
        'paramId': 'filterCutoff',
        'amount': 0.75,
      };
      final edge = ModulationEdgeSnapshot.fromMap(map);

      expect(edge.lfoId, 1);
      expect(edge.deviceId, 'dev-osc-1');
      expect(edge.paramId, 'filterCutoff');
      expect(edge.amount, 0.75);
    });

    test('handles missing fields with constructor defaults', () {
      final edge = ModulationEdgeSnapshot.fromMap(<dynamic, dynamic>{});
      expect(edge.lfoId, 0);
      expect(edge.deviceId, '');
      expect(edge.paramId, '');
      expect(edge.amount, 0.0);
    });
  });

  group('ProjectSnapshot.fromMap with lfos + modEdges', () {
    test('parses lfos and modEdges arrays', () {
      final snapshot = ProjectSnapshot.fromMap({
        'bpm': 120,
        'playheadBeats': 0.0,
        'playing': false,
        'selectedTrackId': 'track-1',
        'tracks': [
          {
            'id': 'track-1',
            'name': 'Track 1',
            'devices': [],
            'midiClips': [],
            'sampleClips': [],
            'automationClips': [],
          },
        ],
        'master': {'id': 'master', 'gain': 1.0},
        'lfos': [
          {'id': 1, 'type': 'lfo', 'waveform': 0, 'rate': 1.0},
          {'id': 2, 'type': 'envelope', 'curveType': 0},
        ],
        'modEdges': [
          {
            'lfoId': 1,
            'deviceId': 'dev-1',
            'paramId': 'filterCutoff',
            'amount': 0.75,
          },
        ],
      });

      expect(snapshot.lfos.length, 2);
      expect(snapshot.modEdges.length, 1);
      expect(snapshot.lfos.first.id, 1);
      expect(snapshot.lfos.first.type, 'lfo');
      expect(snapshot.lfos.last.id, 2);
      expect(snapshot.lfos.last.type, 'envelope');
      expect(snapshot.modEdges.first.lfoId, 1);
      expect(snapshot.modEdges.first.deviceId, 'dev-1');
      expect(snapshot.modEdges.first.paramId, 'filterCutoff');
      expect(snapshot.modEdges.first.amount, 0.75);
    });
  });

  group('Edge cases', () {
    test('handles null values gracefully', () {
      final lfo = LfoSnapshot.fromMap(<dynamic, dynamic>{
        'id': null,
        'type': null,
        'retrigger': null,
        'waveform': null,
        'rate': null,
        'syncDivision': null,
        'phase': null,
        'polarity': null,
        'attack': null,
        'decay': null,
        'sustain': null,
        'release': null,
        'delay': null,
      });
      expect(lfo.id, 0);
      expect(lfo.type, 'lfo');
      expect(lfo.retrigger, 0);
      expect(lfo.waveform, 0);
      expect(lfo.rate, 1.0);
      expect(lfo.syncDivision, 0);
      expect(lfo.phase, 0.0);
      expect(lfo.polarity, 0);
      expect(lfo.attack, 0.1);
      expect(lfo.decay, 0.25);
      expect(lfo.sustain, 0.7);
      expect(lfo.release, 0.35);
      expect(lfo.delay, 0.0);
      expect(lfo.attackCurve, 0.5);
      expect(lfo.decayCurve, 0.5);
      expect(lfo.releaseCurve, 0.5);
      expect(lfo.analogMode, 0);
    });

    test('handles negative amounts in ModulationEdgeSnapshot', () {
      final edge = ModulationEdgeSnapshot.fromMap(<dynamic, dynamic>{
        'lfoId': 2,
        'deviceId': 'dev-filter',
        'paramId': 'cutoff',
        'amount': -0.5,
      });
      expect(edge.lfoId, 2);
      expect(edge.deviceId, 'dev-filter');
      expect(edge.paramId, 'cutoff');
      expect(edge.amount, -0.5);
    });

    test('handles zero IDs', () {
      final lfo = LfoSnapshot.fromMap(<dynamic, dynamic>{
        'id': 0,
        'type': 'lfo',
        'waveform': 0,
        'rate': 1.0,
      });
      expect(lfo.id, 0);
      expect(lfo.type, 'lfo');
      expect(lfo.waveform, 0);
      expect(lfo.rate, 1.0);

      final edge = ModulationEdgeSnapshot.fromMap(<dynamic, dynamic>{
        'lfoId': 0,
        'deviceId': 'dev-zero',
        'paramId': 'gain',
        'amount': 0.0,
      });
      expect(edge.lfoId, 0);
      expect(edge.deviceId, 'dev-zero');
      expect(edge.paramId, 'gain');
      expect(edge.amount, 0.0);
    });
  });
}