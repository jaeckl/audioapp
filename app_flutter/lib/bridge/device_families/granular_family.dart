part of '../device_snapshot.dart';

class GranularDeviceSnapshot extends DeviceSnapshot {
  const GranularDeviceSnapshot(
      {required super.id,
      required super.bypassed,
      this.sampleId = 'sample_form_source',
      this.position = .25,
      this.scan = .15,
      this.grainSize = .35,
      this.density = .35,
      this.spray = .1,
      this.grainPitch = .5,
      this.formant = .5,
      this.character = .45,
      this.regionStart = 0,
      this.regionEnd = 1,
      this.attack = .02,
      this.release = .25,
      this.spread = .35,
      this.formX = .5,
      this.formY = .05,
      this.vowel = 0})
      : super(
            type: 'granular_formant_synth',
            gain: 1,
            pan: .5,
            meterGainReductionDb: 0,
            meterInputLevel: 0);
  final String sampleId;
  final double position,
      scan,
      grainSize,
      density,
      spray,
      grainPitch,
      formant,
      character,
      regionStart,
      regionEnd,
      attack,
      release,
      spread,
      formX,
      formY;
  final int vowel;
  factory GranularDeviceSnapshot.fromMap(Map<dynamic, dynamic> m) {
    final p = m['parameters'] as Map<dynamic, dynamic>? ?? const {};
    double d(String k, double x) => (p[k] as num?)?.toDouble() ?? x;
    final vowel = (p['vowel'] as num?)?.toInt().clamp(0, 5) ?? 0;
    const legacyPoints = [
      [.5, .05],
      [.88, .25],
      [.88, .75],
      [.12, .25],
      [.12, .75],
      [.5, .95]
    ];
    return GranularDeviceSnapshot(
        id: m['id'] as String? ?? '',
        bypassed: readBypass(m['bypass']),
        sampleId: p['sampleId'] as String? ?? 'sample_form_source',
        position: d('position', .25),
        scan: d('scan', .15),
        grainSize: d('grainSize', .35),
        density: d('density', .35),
        spray: d('spray', .1),
        grainPitch: d('grainPitch', .5),
        formant: d('formant', .5),
        character: d('character', .45),
        regionStart: d('regionStart', 0),
        regionEnd: d('regionEnd', 1),
        attack: d('attack', .02),
        release: d('release', .25),
        spread: d('spread', .35),
        formX: d('formX', legacyPoints[vowel][0]),
        formY: d('formY', legacyPoints[vowel][1]),
        vowel: vowel);
  }
  @override
  GranularDeviceSnapshot withParameter(String k, double v) => copyWith(
      position: k == 'position' ? v : null,
      scan: k == 'scan' ? v : null,
      grainSize: k == 'grainSize' ? v : null,
      density: k == 'density' ? v : null,
      spray: k == 'spray' ? v : null,
      grainPitch: k == 'grainPitch' ? v : null,
      formant: k == 'formant' ? v : null,
      character: k == 'character' ? v : null,
      regionStart: k == 'regionStart' ? v : null,
      regionEnd: k == 'regionEnd' ? v : null,
      attack: k == 'attack' ? v : null,
      release: k == 'release' ? v : null,
      spread: k == 'spread' ? v : null,
      formX: k == 'formX' ? v : null,
      formY: k == 'formY' ? v : null,
      vowel: k == 'vowel' ? v.round() : null,
      bypassed: k == 'bypass' ? v >= .5 : null);
  @override
  GranularDeviceSnapshot copyWith(
          {String? id,
          String? type,
          double? gain,
          double? pan,
          bool? bypassed,
          double? meterGainReductionDb,
          double? meterInputLevel,
          String? sampleId,
          double? position,
          double? scan,
          double? grainSize,
          double? density,
          double? spray,
          double? grainPitch,
          double? formant,
          double? character,
          double? regionStart,
          double? regionEnd,
          double? attack,
          double? release,
          double? spread,
          double? formX,
          double? formY,
          int? vowel}) =>
      GranularDeviceSnapshot(
          id: id ?? this.id,
          bypassed: bypassed ?? this.bypassed,
          sampleId: sampleId ?? this.sampleId,
          position: position ?? this.position,
          scan: scan ?? this.scan,
          grainSize: grainSize ?? this.grainSize,
          density: density ?? this.density,
          spray: spray ?? this.spray,
          grainPitch: grainPitch ?? this.grainPitch,
          formant: formant ?? this.formant,
          character: character ?? this.character,
          regionStart: regionStart ?? this.regionStart,
          regionEnd: regionEnd ?? this.regionEnd,
          attack: attack ?? this.attack,
          release: release ?? this.release,
          spread: spread ?? this.spread,
          formX: formX ?? this.formX,
          formY: formY ?? this.formY,
          vowel: vowel ?? this.vowel);
}
