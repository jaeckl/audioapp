import 'package:flutter_test/flutter_test.dart';
import 'package:audioapp/bridge/project_snapshot.dart';

void main() {
  group('LfoSnapshot.fromMap', () {
    test('parses all 13 fields', () {
      // Engine JSON map: 13 fields matching LfoSnapshot constructor
      const map = <dynamic, dynamic>{
        'id': 7,
        'modulatorType': 2,
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
        'name': 'LFO 1',
      };
      final lfo = LfoSnapshot.fromMap(map);

      expect(lfo.id, 7);
      expect(lfo.modulatorType, 2);
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
      expect(lfo.name, 'LFO 1');
    });

    test('handles missing fields with constructor defaults', () {
      final lfo = LfoSnapshot.fromMap(<dynamic, dynamic>{});
      // All defaults match LfoSnapshot constructor (lines 1206-1219)
      expect(lfo.id, 0);
      expect(lfo.modulatorType, 0);
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
      expect(lfo.name, '');
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
      // All defaults match ModulationEdgeSnapshot constructor (lines 1299-1302)
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
          {'id': 1, 'modulatorType': 0, 'waveform': 0, 'rate': 1.0},
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

      expect(snapshot.lfos.length, 1);
      expect(snapshot.modEdges.length, 1);
      expect(snapshot.lfos.first.id, 1);
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
        'modulatorType': null,
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
        'name': null,
      });
      // null values fall through to ?? defaults
      expect(lfo.id, 0);
      expect(lfo.modulatorType, 0);
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
      expect(lfo.name, '');
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
        'modulatorType': 0,
        'waveform': 0,
        'rate': 1.0,
        'name': '',
      });
      expect(lfo.id, 0);
      expect(lfo.modulatorType, 0);
      expect(lfo.waveform, 0);
      expect(lfo.rate, 1.0);
      expect(lfo.name, '');

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