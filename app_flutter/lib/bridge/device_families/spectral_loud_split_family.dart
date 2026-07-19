part of '../device_snapshot.dart';

/// Spectral loudness split: PRE FX → loud/mid/quiet bands → POST FX → Mix.
class SpectralLoudSplitDeviceSnapshot extends DeviceSnapshot {
  const SpectralLoudSplitDeviceSnapshot({
    required super.id,
    required super.type,
    required super.bypassed,
    this.highDb = -18,
    this.lowDb = -40,
    this.bandGains = const [1, 1, 1],
    this.bandSolos = const [false, false, false],
    this.bands = const [[], [], []],
    this.preFxDevices = const [],
    this.postFxDevices = const [],
    this.outputMix = 1,
  }) : super(
          gain: 1,
          pan: 0.5,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
        );

  final double highDb;
  final double lowDb;
  final List<double> bandGains;
  final List<bool> bandSolos;
  final List<List<DeviceSnapshot>> bands;
  final List<DeviceSnapshot> preFxDevices;
  final List<DeviceSnapshot> postFxDevices;
  final double outputMix;

  static const bandLabels = ['LOUD', 'MID', 'QUIET'];

  List<DeviceSnapshot> bandDevices(int bandIndex) =>
      bandIndex >= 0 && bandIndex < bands.length ? bands[bandIndex] : const [];

  double bandGainAt(int i) =>
      i >= 0 && i < bandGains.length ? bandGains[i] : 1;

  bool bandSoloAt(int i) =>
      i >= 0 && i < bandSolos.length ? bandSolos[i] : false;

  factory SpectralLoudSplitDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final p = map['parameters'] as Map<dynamic, dynamic>? ?? const {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? const {};
    final gains = <double>[];
    final solos = <bool>[];
    for (var i = 0; i < 3; i++) {
      gains.add((p['band${i}Gain'] as num?)?.toDouble() ?? 1);
      solos.add(((p['band${i}Solo'] as num?)?.toDouble() ?? 0) >= 0.5);
    }
    final rawBands = map['bands'] as List? ?? const [];
    final bands = <List<DeviceSnapshot>>[];
    for (var i = 0; i < 3; i++) {
      if (i >= rawBands.length || rawBands[i] is! Map) {
        bands.add(const []);
        continue;
      }
      bands.add(parseDeviceList(rawBands[i] as Map, 'devices'));
    }
    return SpectralLoudSplitDeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'spectral_loud_split',
      bypassed: readBypass(map['bypass']),
      highDb: (p['highDb'] as num?)?.toDouble() ?? -18,
      lowDb: (p['lowDb'] as num?)?.toDouble() ?? -40,
      bandGains: gains,
      bandSolos: solos,
      bands: bands,
      preFxDevices: parseDeviceList(map['preFx'] as Map? ?? const {}, 'devices'),
      postFxDevices:
          parseDeviceList(map['postFx'] as Map? ?? const {}, 'devices'),
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (p['outputMix'] as num?)?.toDouble() ??
          1,
    );
  }

  @override
  SpectralLoudSplitDeviceSnapshot withParameter(String id, double value) {
    if (id == 'outputMix') {
      return SpectralLoudSplitDeviceSnapshot(
        id: this.id,
        type: type,
        bypassed: bypassed,
        highDb: highDb,
        lowDb: lowDb,
        bandGains: bandGains,
        bandSolos: bandSolos,
        bands: bands,
        preFxDevices: preFxDevices,
        postFxDevices: postFxDevices,
        outputMix: value.clamp(0, 1),
      );
    }
    if (id == 'highDb') {
      return copyWith(highDb: value.clamp(lowDb + 6, 0));
    }
    if (id == 'lowDb') {
      return copyWith(lowDb: value.clamp(-80, highDb - 6));
    }
    if (id.startsWith('band') && id.endsWith('Gain')) {
      final i = int.tryParse(id.substring(4, 5)) ?? -1;
      if (i >= 0 && i < 3) {
        final gains = List<double>.from(bandGains);
        while (gains.length < 3) {
          gains.add(1);
        }
        gains[i] = value.clamp(0, 2);
        return copyWith(bandGains: gains);
      }
    }
    if (id.startsWith('band') && id.endsWith('Solo')) {
      final i = int.tryParse(id.substring(4, 5)) ?? -1;
      if (i >= 0 && i < 3) {
        final solos = List<bool>.filled(3, false);
        for (var s = 0; s < bandSolos.length && s < 3; s++) {
          solos[s] = bandSolos[s];
        }
        final enable = value >= 0.5;
        if (enable) {
          for (var s = 0; s < 3; s++) {
            solos[s] = s == i;
          }
        } else {
          solos[i] = false;
        }
        return copyWith(bandSolos: solos);
      }
    }
    if (id == 'bypass') {
      return copyWith(bypassed: value >= 0.5);
    }
    return this;
  }

  @override
  SpectralLoudSplitDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? highDb,
    double? lowDb,
    List<double>? bandGains,
    List<bool>? bandSolos,
    List<List<DeviceSnapshot>>? bands,
    List<DeviceSnapshot>? preFxDevices,
    List<DeviceSnapshot>? postFxDevices,
    double? outputMix,
  }) =>
      SpectralLoudSplitDeviceSnapshot(
        id: id ?? this.id,
        type: type ?? this.type,
        bypassed: bypassed ?? this.bypassed,
        highDb: highDb ?? this.highDb,
        lowDb: lowDb ?? this.lowDb,
        bandGains: bandGains ?? this.bandGains,
        bandSolos: bandSolos ?? this.bandSolos,
        bands: bands ?? this.bands,
        preFxDevices: preFxDevices ?? this.preFxDevices,
        postFxDevices: postFxDevices ?? this.postFxDevices,
        outputMix: outputMix ?? this.outputMix,
      );
}
