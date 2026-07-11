part of '../device_snapshot.dart';

class ChorusDeviceSnapshot extends EffectDeviceSnapshot {
  const ChorusDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    this.modeMorph = 0,
    this.classic = const [0.286, 0.25, 0.30, 0.0, 0.5, 0.0],
    this.ensemble = const [0.25, 0.50, 0.50, 0.65, 0.25, 0.65],
    this.dimension = const [0.50, 0.35, 0.80, 0.25, 0.0, 0.90],
    this.drift = const [0.30, 0.50, 0.40, 0.40, 0.70, 0.60],
  }) : super(type: 'chorus');

  final double modeMorph;
  final List<double> classic;
  final List<double> ensemble;
  final List<double> dimension;
  final List<double> drift;

  double get chorusRateHz => 0.1 + classic[0] * 4.9;
  double get chorusDepth => classic[1];
  double get chorusCentreDelayMs => 2 + classic[2] * 18;
  double get chorusFeedback => classic[3] * 0.8;

  static List<double> _bank(
    dynamic value,
    List<double> fallback,
  ) {
    if (value is! List || value.length < 6) return List<double>.from(fallback);
    return List<double>.generate(
      6,
      (index) => (value[index] as num?)?.toDouble() ?? fallback[index],
    );
  }

  factory ChorusDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ChorusDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      modeMorph: (params['modeMorph'] as num?)?.toDouble() ?? 0,
      classic: params['classic'] is List
          ? _bank(params['classic'], const [0.286, 0.25, 0.30, 0, 0.5, 0])
          : <double>[
              (((params['rateHz'] as num?)?.toDouble() ?? 1.5) - 0.1) / 4.9,
              (params['depth'] as num?)?.toDouble() ?? 0.25,
              ((((params['centreDelayMs'] as num?)?.toDouble() ?? 7) - 2) / 18)
                  .clamp(0.0, 1.0),
              ((params['feedback'] as num?)?.toDouble() ?? 0) / 0.8,
              0.5,
              0,
            ],
      ensemble:
          _bank(params['ensemble'], const [0.25, 0.50, 0.50, 0.65, 0.25, 0.65]),
      dimension:
          _bank(params['dimension'], const [0.50, 0.35, 0.80, 0.25, 0.0, 0.90]),
      drift: _bank(params['drift'], const [0.30, 0.50, 0.40, 0.40, 0.70, 0.60]),
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ?? 0.4,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  ChorusDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? modeMorph,
    List<double>? classic,
    List<double>? ensemble,
    List<double>? dimension,
    List<double>? drift,
  }) {
    return ChorusDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      modeMorph: modeMorph ?? this.modeMorph,
      classic: classic ?? this.classic,
      ensemble: ensemble ?? this.ensemble,
      dimension: dimension ?? this.dimension,
      drift: drift ?? this.drift,
    );
  }

  @override
  ChorusDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'modeMorph' => copyWith(modeMorph: value),
      'classicRate' => copyWith(classic: _withBankValue(classic, 0, value)),
      'classicDepth' => copyWith(classic: _withBankValue(classic, 1, value)),
      'classicDelay' => copyWith(classic: _withBankValue(classic, 2, value)),
      'classicFeedback' => copyWith(classic: _withBankValue(classic, 3, value)),
      'classicPhase' => copyWith(classic: _withBankValue(classic, 4, value)),
      'classicShape' => copyWith(classic: _withBankValue(classic, 5, value)),
      'ensembleRate' => copyWith(ensemble: _withBankValue(ensemble, 0, value)),
      'ensembleDepth' => copyWith(ensemble: _withBankValue(ensemble, 1, value)),
      'ensembleVoices' =>
        copyWith(ensemble: _withBankValue(ensemble, 2, value)),
      'ensembleSpread' =>
        copyWith(ensemble: _withBankValue(ensemble, 3, value)),
      'ensembleDrift' => copyWith(ensemble: _withBankValue(ensemble, 4, value)),
      'ensembleTone' => copyWith(ensemble: _withBankValue(ensemble, 5, value)),
      'dimensionAmount' =>
        copyWith(dimension: _withBankValue(dimension, 0, value)),
      'dimensionDelay' =>
        copyWith(dimension: _withBankValue(dimension, 1, value)),
      'dimensionSpread' =>
        copyWith(dimension: _withBankValue(dimension, 2, value)),
      'dimensionMotion' =>
        copyWith(dimension: _withBankValue(dimension, 3, value)),
      'dimensionLowCut' =>
        copyWith(dimension: _withBankValue(dimension, 4, value)),
      'dimensionHighCut' =>
        copyWith(dimension: _withBankValue(dimension, 5, value)),
      'driftSpeed' => copyWith(drift: _withBankValue(drift, 0, value)),
      'driftDepth' => copyWith(drift: _withBankValue(drift, 1, value)),
      'driftWander' => copyWith(drift: _withBankValue(drift, 2, value)),
      'driftDelay' => copyWith(drift: _withBankValue(drift, 3, value)),
      'driftStereo' => copyWith(drift: _withBankValue(drift, 4, value)),
      'driftTone' => copyWith(drift: _withBankValue(drift, 5, value)),
      _ => this,
    };
  }

  static List<double> _withBankValue(
    List<double> bank,
    int index,
    double value,
  ) {
    final copy = List<double>.from(bank);
    copy[index] = value;
    return copy;
  }
}
