import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhaseModSynth DeviceSnapshot', () {
    test('F1: FromMap parses all PM fields', () {
      final map = <dynamic, dynamic>{
        'id': 'pm-test',
        'type': 'phase_mod_synth',
        'parameters': <dynamic, dynamic>{
          'pmOp1Ratio': 0.0625,
          'pmOp1Fine': 0.5,
          'pmOp1Level': 0.8,
          'pmOp1Wave': 0.0,
          'pmOp1Attack': 0.01,
          'pmOp1Decay': 0.3,
          'pmOp1Sustain': 0.8,
          'pmOp1Release': 0.4,
          'pmOp1VelSense': 1.0,
          'pmOp1KeyTrack': 0.0,
          'pmOp2Ratio': 0.4375,
          'pmOp2Fine': 0.5,
          'pmOp2Level': 0.4,
          'pmOp2Wave': 0.0,
          'pmOp2Attack': 0.01,
          'pmOp2Decay': 0.3,
          'pmOp2Sustain': 0.8,
          'pmOp2Release': 0.4,
          'pmOp2VelSense': 1.0,
          'pmOp2KeyTrack': 0.0,
          'pmOp3Ratio': 0.75,
          'pmOp3Fine': 0.5,
          'pmOp3Level': 0.0,
          'pmOp3Wave': 0.0,
          'pmOp3Attack': 0.01,
          'pmOp3Decay': 0.3,
          'pmOp3Sustain': 0.8,
          'pmOp3Release': 0.4,
          'pmOp3VelSense': 1.0,
          'pmOp3KeyTrack': 0.0,
          'pmOp4Ratio': 0.375,
          'pmOp4Fine': 0.5,
          'pmOp4Level': 0.0,
          'pmOp4Wave': 0.0,
          'pmOp4Attack': 0.01,
          'pmOp4Decay': 0.3,
          'pmOp4Sustain': 0.8,
          'pmOp4Release': 0.4,
          'pmOp4VelSense': 1.0,
          'pmOp4KeyTrack': 0.0,
          'pmAlgoIndex': 0,
          'pmFeedback': 0.0,
          'pmUnisonVoices': 0.0,
          'pmUnisonDetune': 0.15,
          'pmGlide': 0.0,
          'pmMono': 0.0,
          'pmLegato': 0.0,
          'pmMasterVol': 0.85,
          'pmLfoRate': 0.2,
          'pmLfoShape': 0.0,
          'pmLfoAmount': 0.0,
          'pmLfoDest': 0,
          'pmVibratoDepth': 0.0,
          'pmVibratoRate': 0.3,
        },
      };
      final snapshot = DeviceSnapshot.fromMap(map) as PhaseModSynthDeviceSnapshot;
      expect(snapshot.pmOp1Ratio, 0.0625);
      expect(snapshot.pmOp1Fine, 0.5);
      expect(snapshot.pmOp1Level, 0.8);
      expect(snapshot.pmOp1Wave, 0.0);
      expect(snapshot.pmOp1Attack, 0.01);
      expect(snapshot.pmOp1Decay, 0.3);
      expect(snapshot.pmOp1Sustain, 0.8);
      expect(snapshot.pmOp1Release, 0.4);
      expect(snapshot.pmOp1VelSense, 1.0);
      expect(snapshot.pmOp1KeyTrack, 0.0);
      expect(snapshot.pmOp2Ratio, 0.4375);
      expect(snapshot.pmOp2Fine, 0.5);
      expect(snapshot.pmOp2Level, 0.4);
      expect(snapshot.pmOp2Wave, 0.0);
      expect(snapshot.pmOp2Attack, 0.01);
      expect(snapshot.pmOp2Decay, 0.3);
      expect(snapshot.pmOp2Sustain, 0.8);
      expect(snapshot.pmOp2Release, 0.4);
      expect(snapshot.pmOp2VelSense, 1.0);
      expect(snapshot.pmOp2KeyTrack, 0.0);
      expect(snapshot.pmOp3Ratio, 0.75);
      expect(snapshot.pmOp3Fine, 0.5);
      expect(snapshot.pmOp3Level, 0.0);
      expect(snapshot.pmOp3Wave, 0.0);
      expect(snapshot.pmOp3Attack, 0.01);
      expect(snapshot.pmOp3Decay, 0.3);
      expect(snapshot.pmOp3Sustain, 0.8);
      expect(snapshot.pmOp3Release, 0.4);
      expect(snapshot.pmOp3VelSense, 1.0);
      expect(snapshot.pmOp3KeyTrack, 0.0);
      expect(snapshot.pmOp4Ratio, 0.375);
      expect(snapshot.pmOp4Fine, 0.5);
      expect(snapshot.pmOp4Level, 0.0);
      expect(snapshot.pmOp4Wave, 0.0);
      expect(snapshot.pmOp4Attack, 0.01);
      expect(snapshot.pmOp4Decay, 0.3);
      expect(snapshot.pmOp4Sustain, 0.8);
      expect(snapshot.pmOp4Release, 0.4);
      expect(snapshot.pmOp4VelSense, 1.0);
      expect(snapshot.pmOp4KeyTrack, 0.0);
      expect(snapshot.pmAlgoIndex, 0);
      expect(snapshot.pmFeedback, 0.0);
      expect(snapshot.pmUnisonVoices, 0.0);
      expect(snapshot.pmUnisonDetune, 0.15);
      expect(snapshot.pmGlide, 0.0);
      expect(snapshot.pmMono, 0.0);
      expect(snapshot.pmLegato, 0.0);
      expect(snapshot.pmMasterVol, 0.85);
      expect(snapshot.pmLfoRate, 0.2);
      expect(snapshot.pmLfoShape, 0.0);
      expect(snapshot.pmLfoAmount, 0.0);
      expect(snapshot.pmLfoDest, 0);
      expect(snapshot.pmVibratoDepth, 0.0);
      expect(snapshot.pmVibratoRate, 0.3);
    });

    test('F2: FromMap applies defaults when PM fields missing', () {
      final map = <dynamic, dynamic>{
        'id': 'pm-test',
        'type': 'phase_mod_synth',
        'parameters': <dynamic, dynamic>{},
      };
      final snapshot = DeviceSnapshot.fromMap(map) as PhaseModSynthDeviceSnapshot;
      expect(snapshot.pmOp1Ratio, 0.0625);
      expect(snapshot.pmOp1Fine, 0.5);
      expect(snapshot.pmOp1Level, 0.8);
      expect(snapshot.pmOp1Wave, 0.0);
      expect(snapshot.pmOp1Attack, 0.01);
      expect(snapshot.pmOp1Decay, 0.3);
      expect(snapshot.pmOp1Sustain, 0.8);
      expect(snapshot.pmOp1Release, 0.4);
      expect(snapshot.pmOp1VelSense, 1.0);
      expect(snapshot.pmOp1KeyTrack, 0.0);
      expect(snapshot.pmOp2Ratio, 0.4375);
      expect(snapshot.pmOp2Fine, 0.5);
      expect(snapshot.pmOp2Level, 0.4);
      expect(snapshot.pmOp2Wave, 0.0);
      expect(snapshot.pmOp2Attack, 0.01);
      expect(snapshot.pmOp2Decay, 0.3);
      expect(snapshot.pmOp2Sustain, 0.8);
      expect(snapshot.pmOp2Release, 0.4);
      expect(snapshot.pmOp2VelSense, 1.0);
      expect(snapshot.pmOp2KeyTrack, 0.0);
      expect(snapshot.pmOp3Ratio, 0.75);
      expect(snapshot.pmOp3Fine, 0.5);
      expect(snapshot.pmOp3Level, 0.0);
      expect(snapshot.pmOp3Wave, 0.0);
      expect(snapshot.pmOp3Attack, 0.01);
      expect(snapshot.pmOp3Decay, 0.3);
      expect(snapshot.pmOp3Sustain, 0.8);
      expect(snapshot.pmOp3Release, 0.4);
      expect(snapshot.pmOp3VelSense, 1.0);
      expect(snapshot.pmOp3KeyTrack, 0.0);
      expect(snapshot.pmOp4Ratio, 0.375);
      expect(snapshot.pmOp4Fine, 0.5);
      expect(snapshot.pmOp4Level, 0.0);
      expect(snapshot.pmOp4Wave, 0.0);
      expect(snapshot.pmOp4Attack, 0.01);
      expect(snapshot.pmOp4Decay, 0.3);
      expect(snapshot.pmOp4Sustain, 0.8);
      expect(snapshot.pmOp4Release, 0.4);
      expect(snapshot.pmOp4VelSense, 1.0);
      expect(snapshot.pmOp4KeyTrack, 0.0);
      expect(snapshot.pmAlgoIndex, 0);
      expect(snapshot.pmFeedback, 0.0);
      expect(snapshot.pmUnisonVoices, 0.0);
      expect(snapshot.pmUnisonDetune, 0.15);
      expect(snapshot.pmGlide, 0.0);
      expect(snapshot.pmMono, 0.0);
      expect(snapshot.pmLegato, 0.0);
      expect(snapshot.pmMasterVol, 0.85);
      expect(snapshot.pmLfoRate, 0.2);
      expect(snapshot.pmLfoShape, 0.0);
      expect(snapshot.pmLfoAmount, 0.0);
      expect(snapshot.pmLfoDest, 0);
      expect(snapshot.pmVibratoDepth, 0.0);
      expect(snapshot.pmVibratoRate, 0.3);
    });

    test('F3: CopyWith preserves existing fields and updates PM fields', () {
      final base = DeviceSnapshot.fromMap(<dynamic, dynamic>{
        'id': 'pm-test',
        'type': 'phase_mod_synth',
        'outputPanel': <dynamic, dynamic>{'gain': 0.8, 'pan': 0.5, 'type': 'stereo'},
        'parameters': <dynamic, dynamic>{},
      }) as PhaseModSynthDeviceSnapshot;

      final updated = base.copyWith(pmOp1Level: 0.9);
      expect(updated.pmOp1Level, 0.9);

      // Other PM fields unchanged
      expect(updated.pmOp1Ratio, 0.0625);
      expect(updated.pmOp1Fine, 0.5);
      expect(updated.pmOp1Wave, 0.0);
      expect(updated.pmAlgoIndex, 0);
      expect(updated.pmFeedback, 0.0);
      expect(updated.pmMasterVol, 0.85);

      // Non-PM fields unchanged
      expect(updated.id, 'pm-test');
      expect(updated.gain, 0.8);
      expect(updated.pan, 0.5);

      // Test algo index copyWith
      final withAlgo = base.copyWith(pmAlgoIndex: 3);
      expect(withAlgo.pmAlgoIndex, 3);
      expect(withAlgo.pmOp1Level, 0.8); // unchanged
    });

    group('WithParameter routing', () {
      late PhaseModSynthDeviceSnapshot base;
      setUp(() {
        base = DeviceSnapshot.fromMap(<dynamic, dynamic>{
          'id': 'pm-test',
          'type': 'phase_mod_synth',
          'parameters': <dynamic, dynamic>{},
        }) as PhaseModSynthDeviceSnapshot;
      });

      test('F4a: routes pmOp1Level', () {
        final result = base.withParameter('pmOp1Level', 0.9);
        expect(result.pmOp1Level, 0.9);
      });

      test('F4b: routes pmAlgoIndex', () {
        final result = base.withParameter('pmAlgoIndex', 3);
        expect(result.pmAlgoIndex, 3);
      });

      test('F4c: routes pmFeedback', () {
        final result = base.withParameter('pmFeedback', 0.5);
        expect(result.pmFeedback, 0.5);
      });

      test('F4d: routes pmMasterVol', () {
        final result = base.withParameter('pmMasterVol', 0.7);
        expect(result.pmMasterVol, 0.7);
      });

      test('F4e: routes pmLfoRate', () {
        final result = base.withParameter('pmLfoRate', 0.6);
        expect(result.pmLfoRate, 0.6);
      });

      test('F4f: routes pmUnisonVoices', () {
        final result = base.withParameter('pmUnisonVoices', 0.8);
        expect(result.pmUnisonVoices, 0.8);
      });

      test('F4g: routes pmOp1Ratio', () {
        final result = base.withParameter('pmOp1Ratio', 0.5);
        expect(result.pmOp1Ratio, 0.5);
      });

      test('F4h: routes pmOp1Attack', () {
        final result = base.withParameter('pmOp1Attack', 0.5);
        expect(result.pmOp1Attack, 0.5);
      });

      test('F4i: routes pmOp4Level', () {
        final result = base.withParameter('pmOp4Level', 0.7);
        expect(result.pmOp4Level, 0.7);
      });

      test('F4j: bogus param ID returns unchanged snapshot', () {
        final result = base.withParameter('bogus', 0.5);
        expect(result, same(base));
      });
    });

    test('F5: Preset loading applies PM parameters', () {
      final base = DeviceSnapshot.fromMap(<dynamic, dynamic>{
        'id': 'pm-test',
        'type': 'phase_mod_synth',
        'parameters': <dynamic, dynamic>{},
      }) as PhaseModSynthDeviceSnapshot;

      // Simulate a preset map
      final preset = <String, double>{
        'pmOp1Level': 0.9,
        'pmAlgoIndex': 3,
        'pmOp2Ratio': 0.75,
        'pmFeedback': 0.3,
        'pmMasterVol': 0.6,
        'pmLfoRate': 0.5,
      };

      // Apply preset by iterating over map and calling withParameter
      var result = base;
      for (final entry in preset.entries) {
        result = result.withParameter(entry.key, entry.value);
      }

      expect(result.pmOp1Level, 0.9);
      expect(result.pmAlgoIndex, 3);
      expect(result.pmOp2Ratio, 0.75);
      expect(result.pmFeedback, 0.3);
      expect(result.pmMasterVol, 0.6);
      expect(result.pmLfoRate, 0.5);

      // Default fields unchanged
      expect(result.pmOp1Ratio, 0.0625);
      expect(result.pmGlide, 0.0);
    });
  });
}