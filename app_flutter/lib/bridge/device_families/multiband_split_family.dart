part of '../device_snapshot.dart';

/// 2/3/4-band frequency split container: nested per-band device chains,
/// post-band gains, log-Hz crossovers, and FX Mix/Width output panel.
class MultibandSplitDeviceSnapshot extends DeviceSnapshot {
  const MultibandSplitDeviceSnapshot({
    required super.id,
    required super.type,
    required super.bypassed,
    required this.bandCount,
    this.crossoverHz = const [],
    this.bandGains = const [1, 1, 1, 1],
    this.bands = const [],
    this.outputMix = 1,
    this.outputWidth = 1,
  }) : super(
          gain: 1,
          pan: 0.5,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
        );

  final int bandCount;
  final List<double> crossoverHz;
  final List<double> bandGains;
  final List<List<DeviceSnapshot>> bands;
  final double outputMix;
  final double outputWidth;

  List<DeviceSnapshot> bandDevices(int bandIndex) =>
      bandIndex >= 0 && bandIndex < bands.length ? bands[bandIndex] : const [];

  double bandGainAt(int bandIndex) =>
      bandIndex >= 0 && bandIndex < bandGains.length ? bandGains[bandIndex] : 1;

  double crossoverAt(int index) =>
      index >= 0 && index < crossoverHz.length ? crossoverHz[index] : 1000;

  static List<double> _defaultCrossovers(int bandCount) => switch (bandCount) {
        3 => const [200, 2000],
        4 => const [100, 500, 2000],
        _ => const [1000],
      };

  static List<String> bandLabels(int bandCount) => switch (bandCount) {
        3 => const ['LO', 'MID', 'HI'],
        4 => const ['LO', 'LM', 'HM', 'HI'],
        _ => const ['LO', 'HI'],
      };

  factory MultibandSplitDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String? ?? 'mb_split_2';
    final bandCount = switch (type) {
      'mb_split_3' => 3,
      'mb_split_4' => 4,
      _ => 2,
    };
    final p = map['parameters'] as Map<dynamic, dynamic>? ?? const {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? const {};
    final defaults = _defaultCrossovers(bandCount);

    final xo = <double>[];
    for (var i = 0; i < bandCount - 1; i++) {
      xo.add((p['crossover$i'] as num?)?.toDouble() ?? defaults[i]);
    }

    final gains = <double>[];
    for (var i = 0; i < 4; i++) {
      gains.add((p['band${i}Gain'] as num?)?.toDouble() ?? 1);
    }

    final rawBands = map['bands'] as List? ?? const [];
    final bands = <List<DeviceSnapshot>>[];
    for (var i = 0; i < bandCount; i++) {
      if (i >= rawBands.length || rawBands[i] is! Map) {
        bands.add(const []);
        continue;
      }
      bands.add(parseDeviceList(rawBands[i] as Map, 'devices'));
    }

    return MultibandSplitDeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: type,
      bypassed: readBypass(map['bypass']),
      bandCount: bandCount,
      crossoverHz: xo,
      bandGains: gains,
      bands: bands,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (p['outputMix'] as num?)?.toDouble() ??
          1,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ??
          (p['outputWidth'] as num?)?.toDouble() ??
          1,
    );
  }

  @override
  MultibandSplitDeviceSnapshot withParameter(String id, double value) {
    if (id == 'outputMix') return copyWith(outputMix: value.clamp(0, 1));
    if (id == 'outputWidth') return copyWith(outputWidth: value.clamp(0, 1));
    if (id == 'bypass') return copyWith(bypassed: value >= 0.5);
    if (id.startsWith('band') && id.endsWith('Gain') && id.length == 9) {
      final band = int.tryParse(id[4]);
      if (band != null && band >= 0 && band < 4) {
        final next = List<double>.from(bandGains);
        while (next.length < 4) {
          next.add(1);
        }
        next[band] = value.clamp(0, 2);
        return copyWith(bandGains: next);
      }
    }
    if (id.startsWith('crossover') && id.length == 10) {
      final index = int.tryParse(id[9]);
      if (index != null && index >= 0 && index < bandCount - 1) {
        final next = List<double>.from(crossoverHz);
        next[index] = value.clamp(40, 18000);
        return copyWith(crossoverHz: next);
      }
    }
    return this;
  }

  @override
  MultibandSplitDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    int? bandCount,
    List<double>? crossoverHz,
    List<double>? bandGains,
    List<List<DeviceSnapshot>>? bands,
    double? outputMix,
    double? outputWidth,
  }) =>
      MultibandSplitDeviceSnapshot(
        id: id ?? this.id,
        type: type ?? this.type,
        bypassed: bypassed ?? this.bypassed,
        bandCount: bandCount ?? this.bandCount,
        crossoverHz: crossoverHz ?? this.crossoverHz,
        bandGains: bandGains ?? this.bandGains,
        bands: bands ?? this.bands,
        outputMix: outputMix ?? this.outputMix,
        outputWidth: outputWidth ?? this.outputWidth,
      );

  MultibandSplitDeviceSnapshot withBandDevices(
    int bandIndex,
    List<DeviceSnapshot> devices,
  ) {
    if (bandIndex < 0 || bandIndex >= bandCount) return this;
    final next = [
      for (var i = 0; i < bandCount; i++)
        i == bandIndex
            ? devices
            : (i < bands.length ? bands[i] : const <DeviceSnapshot>[]),
    ];
    return copyWith(bands: next);
  }
}
