import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BassSynth DeviceSnapshot', () {
    test('FromMap parses all bass fields', () {
      final map = <dynamic, dynamic>{
        'id': 'bass-test',
        'type': 'bass_synth',
        'parameters': <dynamic, dynamic>{
          'bassOscShape': 0.7,
          'bassSubMix': 0.3,
          'bassSubOctave': 1,
          'bassNoise': 0.1,
          'bassFilterResonance': 0.5,
          'bassDrive': 0.4,
          'bassSquash': 0.2,
          'bassOctave': 3,
          'bassVelocitySense': 0.9,
        },
      };
      final snapshot = DeviceSnapshot.fromMap(map);
      expect(snapshot.bassOscShape, 0.7);
      expect(snapshot.bassSubMix, 0.3);
      expect(snapshot.bassSubOctave, 1);
      expect(snapshot.bassNoise, 0.1);
      expect(snapshot.bassFilterResonance, 0.5);
      expect(snapshot.bassDrive, 0.4);
      expect(snapshot.bassSquash, 0.2);
      expect(snapshot.bassOctave, 3);
      expect(snapshot.bassVelocitySense, 0.9);
    });

    test('FromMap applies defaults when bass fields missing', () {
      final map = <dynamic, dynamic>{
        'id': 'bass-test',
        'type': 'bass_synth',
        'parameters': <dynamic, dynamic>{},
      };
      final snapshot = DeviceSnapshot.fromMap(map);
      expect(snapshot.bassOscShape, 0.3);
      expect(snapshot.bassSubMix, 0.5);
      expect(snapshot.bassSubOctave, 0);
      expect(snapshot.bassNoise, 0.0);
      expect(snapshot.bassFilterResonance, 0.25);
      expect(snapshot.bassDrive, 0.0);
      expect(snapshot.bassSquash, 0.0);
      expect(snapshot.bassOctave, 2);
      expect(snapshot.bassVelocitySense, 1.0);
    });

    test('CopyWith preserves existing fields and updates bass fields', () {
      const base = DeviceSnapshot(
        id: 'bass-test',
        type: 'bass_synth',
        frequencyHz: 220.0,
        gain: 0.8,
        pan: 0.5,
        sampleId: '',
        attack: 0.01,
        decay: 0.3,
        sustain: 0.7,
        release: 0.4,
        filterCutoff: 0.75,
        filterQ: 0.35,
        filterMode: 0,
        trimStartSec: 0.0,
        trimEndSec: 0.0,
      );

      final updated = base.copyWith(bassOscShape: 0.9);
      expect(updated.bassOscShape, 0.9);
      expect(updated.bassSubMix, 0.5);
      expect(updated.bassSubOctave, 0);
      expect(updated.bassNoise, 0.0);
      expect(updated.bassFilterResonance, 0.25);
      expect(updated.bassDrive, 0.0);
      expect(updated.bassSquash, 0.0);
      expect(updated.bassOctave, 2);
      expect(updated.bassVelocitySense, 1.0);
    });

    group('WithParameter routing', () {
      late DeviceSnapshot base;
      setUp(() {
        base = DeviceSnapshot.fromMap(<dynamic, dynamic>{
          'id': 'bass-test',
          'type': 'bass_synth',
          'parameters': <dynamic, dynamic>{},
        });
      });

      test('routes bassOscShape', () {
        expect(base.withParameter('bassOscShape', 0.8).bassOscShape, 0.8);
      });

      test('routes bassSubMix', () {
        expect(base.withParameter('bassSubMix', 0.6).bassSubMix, 0.6);
      });

      test('routes bassSubOctave', () {
        expect(base.withParameter('bassSubOctave', 2).bassSubOctave, 2);
      });

      test('routes bassNoise', () {
        expect(base.withParameter('bassNoise', 0.3).bassNoise, 0.3);
      });

      test('routes bassFilterResonance', () {
        expect(
          base.withParameter('bassFilterResonance', 0.7).bassFilterResonance,
          0.7,
        );
      });

      test('routes bassDrive', () {
        expect(base.withParameter('bassDrive', 0.5).bassDrive, 0.5);
      });

      test('routes bassSquash', () {
        expect(base.withParameter('bassSquash', 0.4).bassSquash, 0.4);
      });

      test('routes bassOctave', () {
        expect(base.withParameter('bassOctave', 4).bassOctave, 4);
      });

      test('routes bassVelocitySense', () {
        expect(
          base.withParameter('bassVelocitySense', 0.7).bassVelocitySense,
          0.7,
        );
      });

      test('bogus param ID returns unchanged snapshot', () {
        final result = base.withParameter('nonexistent', 0.5);
        expect(result, same(base));
      });
    });

    group('WithParameter clamping', () {
      late DeviceSnapshot base;
      setUp(() {
        base = DeviceSnapshot.fromMap(<dynamic, dynamic>{
          'id': 'bass-test',
          'type': 'bass_synth',
          'parameters': <dynamic, dynamic>{},
        });
      });

      test('clamps bassOscShape to [0..1]', () {
        expect(base.withParameter('bassOscShape', 1.5).bassOscShape, 1.0);
        expect(base.withParameter('bassOscShape', -0.5).bassOscShape, 0.0);
      });

      test('clamps bassSubMix to [0..1]', () {
        expect(base.withParameter('bassSubMix', 1.5).bassSubMix, 1.0);
        expect(base.withParameter('bassSubMix', -0.5).bassSubMix, 0.0);
      });

      test('clamps bassSubOctave to [0..2]', () {
        expect(base.withParameter('bassSubOctave', 5).bassSubOctave, 2);
        expect(base.withParameter('bassSubOctave', -1).bassSubOctave, 0);
      });

      test('clamps bassNoise to [0..1]', () {
        expect(base.withParameter('bassNoise', 1.5).bassNoise, 1.0);
        expect(base.withParameter('bassNoise', -0.1).bassNoise, 0.0);
      });

      test('clamps bassFilterResonance to [0..1]', () {
        expect(
          base.withParameter('bassFilterResonance', 2.0).bassFilterResonance,
          1.0,
        );
        expect(
          base.withParameter('bassFilterResonance', -1.0).bassFilterResonance,
          0.0,
        );
      });

      test('clamps bassDrive to [0..1]', () {
        expect(base.withParameter('bassDrive', 1.5).bassDrive, 1.0);
        expect(base.withParameter('bassDrive', -0.5).bassDrive, 0.0);
      });

      test('clamps bassSquash to [0..1]', () {
        expect(base.withParameter('bassSquash', 1.5).bassSquash, 1.0);
        expect(base.withParameter('bassSquash', -0.5).bassSquash, 0.0);
      });

      test('clamps bassOctave to [0..4]', () {
        expect(base.withParameter('bassOctave', -1).bassOctave, 0);
        expect(base.withParameter('bassOctave', 6).bassOctave, 4);
      });

      test('clamps bassVelocitySense to [0..1]', () {
        expect(
          base.withParameter('bassVelocitySense', 2.0).bassVelocitySense,
          1.0,
        );
        expect(
          base.withParameter('bassVelocitySense', -0.5).bassVelocitySense,
          0.0,
        );
      });
    });
  });
}