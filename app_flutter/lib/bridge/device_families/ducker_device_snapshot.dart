part of '../device_snapshot.dart';

class DuckerDeviceSnapshot extends DynamicsDeviceSnapshot
    implements VirtualStripHostSnapshot {
  const DuckerDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.duckThreshold,
    required this.duckDepth,
    required this.duckAttack,
    required this.duckRelease,
    required this.sidechainSourceId,
    this.sidechainGain = 1.0,
    this.audioFxDevices = const [],
    this.noteFxDevices = const [],
  }) : super(type: 'ducker');

  final double duckThreshold;
  final double duckDepth;
  final double duckAttack;
  final double duckRelease;
  final String sidechainSourceId;
  final double sidechainGain;

  @override
  final List<DeviceSnapshot> audioFxDevices;
  @override
  final List<DeviceSnapshot> noteFxDevices;

  factory DuckerDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final inputPanel = map['inputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DuckerDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (inputPanel['trim'] as num?)?.toDouble() ??
          (params['inputGain'] as num?)?.toDouble() ??
          1.0,
      duckThreshold: (params['duckThreshold'] as num?)?.toDouble() ?? 0.45,
      duckDepth: (params['duckDepth'] as num?)?.toDouble() ?? 0.75,
      duckAttack: (params['duckAttack'] as num?)?.toDouble() ?? 0.15,
      duckRelease: (params['duckRelease'] as num?)?.toDouble() ?? 0.45,
      sidechainGain: (params['sidechainGain'] as num?)?.toDouble() ?? 1.0,
      sidechainSourceId: params['sidechainSourceId'] as String? ?? '',
      audioFxDevices: parseDeviceList(map, 'audioFxDevices'),
      noteFxDevices: const [],
    );
  }

  DuckerDeviceSnapshot withSidechainSourceId(String value) =>
      copyWith(sidechainSourceId: value);

  @override
  DuckerDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? duckThreshold,
    double? duckDepth,
    double? duckAttack,
    double? duckRelease,
    String? sidechainSourceId,
    double? sidechainGain,
    List<DeviceSnapshot>? audioFxDevices,
    List<DeviceSnapshot>? noteFxDevices,
  }) {
    return DuckerDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      duckThreshold: duckThreshold ?? this.duckThreshold,
      duckDepth: duckDepth ?? this.duckDepth,
      duckAttack: duckAttack ?? this.duckAttack,
      duckRelease: duckRelease ?? this.duckRelease,
      sidechainSourceId: sidechainSourceId ?? this.sidechainSourceId,
      sidechainGain: sidechainGain ?? this.sidechainGain,
      audioFxDevices: audioFxDevices ?? this.audioFxDevices,
      noteFxDevices: noteFxDevices ?? this.noteFxDevices,
    );
  }

  @override
  DuckerDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'duckThreshold' => copyWith(duckThreshold: value.clamp(0.0, 1.0)),
      'duckDepth' => copyWith(duckDepth: value.clamp(0.0, 1.0)),
      'duckAttack' => copyWith(duckAttack: value.clamp(0.0, 1.0)),
      'duckRelease' => copyWith(duckRelease: value.clamp(0.0, 1.0)),
      'sidechainGain' => copyWith(sidechainGain: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
