/// Shared parsing helpers for device snapshot parameter maps.
///
/// These were originally private top-level functions in
/// the old `device_snapshots.dart` library.
/// They are now public so that per-family
/// snapshot files can reuse them without depending on an umbrella library.
library;

bool readBypass(dynamic value) {
  return switch (value) {
    true => true,
    false => false,
    final num n => n != 0,
    _ => false,
  };
}

double readOscShape(
  Map<dynamic, dynamic> params,
  String shapeKey,
  String legacyWaveKey,
  double fallback,
) {
  if (params.containsKey(shapeKey)) {
    return (params[shapeKey] as num?)?.toDouble() ?? fallback;
  }
  final legacyWave = (params[legacyWaveKey] as num?)?.toInt();
  if (legacyWave != null) {
    return legacyWave / 4.0;
  }
  return fallback;
}

double deriveOscMixFromLegacyLevels(Map<dynamic, dynamic> params) {
  if (params.containsKey('oscMix')) {
    return (params['oscMix'] as num?)?.toDouble() ?? 0.37;
  }
  final osc1Level = (params['osc1Level'] as num?)?.toDouble() ?? 0.85;
  final osc2Level = (params['osc2Level'] as num?)?.toDouble() ?? 0.5;
  final sum = osc1Level + osc2Level;
  if (sum <= 0.001) return 0.37;
  return osc2Level / sum;
}

double readCymbalColor(Map<dynamic, dynamic> params) {
  final color = params['cymbalColor'];
  if (color is num) {
    return color.toDouble();
  }
  final metal = (params['cymbalMetal'] as num?)?.toDouble() ?? 0.55;
  final bright = (params['cymbalBrightness'] as num?)?.toDouble() ?? 0.60;
  return (metal + bright) * 0.5;
}

double readCrashColor(Map<dynamic, dynamic> params) {
  final color = params['crashColor'];
  if (color is num) {
    return color.toDouble();
  }
  final wash = (params['crashWash'] as num?)?.toDouble() ?? 0.60;
  final bright = (params['crashBright'] as num?)?.toDouble() ?? 0.65;
  return (wash + bright) * 0.5;
}