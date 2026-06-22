part of '../device_snapshots.dart';

sealed class DrumGeneratorDeviceSnapshot extends DeviceSnapshot {
  const DrumGeneratorDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
  });
}

class KickGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const KickGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.kickModel,
    required this.kickPitch,
    required this.kickPunch,
    required this.kickDecay,
    required this.kickClick,
    required this.kickTone,
    required this.kickVelocity,
    required this.kickKeyTrack,
  }) : super(type: 'kick_generator');

  final double kickModel;
  final double kickPitch;
  final double kickPunch;
  final double kickDecay;
  final double kickClick;
  final double kickTone;
  final double kickVelocity;
  final double kickKeyTrack;

  factory KickGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return KickGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      kickModel: (params['kickModel'] as num?)?.toDouble() ?? 0.0,
      kickPitch: (params['kickPitch'] as num?)?.toDouble() ?? 0.55,
      kickPunch: (params['kickPunch'] as num?)?.toDouble() ?? 0.60,
      kickDecay: (params['kickDecay'] as num?)?.toDouble() ?? 0.50,
      kickClick: (params['kickClick'] as num?)?.toDouble() ?? 0.35,
      kickTone: (params['kickTone'] as num?)?.toDouble() ?? 0.50,
      kickVelocity: (params['kickVelocity'] as num?)?.toDouble() ?? 1.0,
      kickKeyTrack: (params['kickKeyTrack'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  KickGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? kickModel,
    double? kickPitch,
    double? kickPunch,
    double? kickDecay,
    double? kickClick,
    double? kickTone,
    double? kickVelocity,
    double? kickKeyTrack,
  }) {
    return KickGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      kickModel: kickModel ?? this.kickModel,
      kickPitch: kickPitch ?? this.kickPitch,
      kickPunch: kickPunch ?? this.kickPunch,
      kickDecay: kickDecay ?? this.kickDecay,
      kickClick: kickClick ?? this.kickClick,
      kickTone: kickTone ?? this.kickTone,
      kickVelocity: kickVelocity ?? this.kickVelocity,
      kickKeyTrack: kickKeyTrack ?? this.kickKeyTrack,
    );
  }

  @override
  KickGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'kickModel' => copyWith(kickModel: value.clamp(0.0, 1.0)),
      'kickPitch' => copyWith(kickPitch: value.clamp(0.0, 1.0)),
      'kickPunch' => copyWith(kickPunch: value.clamp(0.0, 1.0)),
      'kickDecay' => copyWith(kickDecay: value.clamp(0.0, 1.0)),
      'kickClick' => copyWith(kickClick: value.clamp(0.0, 1.0)),
      'kickTone' => copyWith(kickTone: value.clamp(0.0, 1.0)),
      'kickVelocity' => copyWith(kickVelocity: value.clamp(0.0, 1.0)),
      'kickKeyTrack' => copyWith(kickKeyTrack: value >= 0.5 ? 1.0 : 0.0),
      _ => this,
    };
  }
}

class SnareGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const SnareGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.snareModel,
    required this.snareBody,
    required this.snareRing,
    required this.snareTune,
    required this.snareSnares,
    required this.snareSnap,
    required this.snareDecay,
    required this.snareVelocity,
  }) : super(type: 'snare_generator');

  final double snareModel;
  final double snareBody;
  final double snareRing;
  final double snareTune;
  final double snareSnares;
  final double snareSnap;
  final double snareDecay;
  final double snareVelocity;

  factory SnareGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return SnareGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      snareModel: (params['snareModel'] as num?)?.toDouble() ?? 0.0,
      snareBody: (params['snareBody'] as num?)?.toDouble() ?? 0.45,
      snareRing: (params['snareRing'] as num?)?.toDouble() ?? 0.40,
      snareTune: (params['snareTune'] as num?)?.toDouble() ?? 0.50,
      snareSnares: (params['snareSnares'] as num?)?.toDouble() ?? 0.60,
      snareSnap: (params['snareSnap'] as num?)?.toDouble() ?? 0.40,
      snareDecay: (params['snareDecay'] as num?)?.toDouble() ?? 0.50,
      snareVelocity: (params['snareVelocity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  SnareGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? snareModel,
    double? snareBody,
    double? snareRing,
    double? snareTune,
    double? snareSnares,
    double? snareSnap,
    double? snareDecay,
    double? snareVelocity,
  }) {
    return SnareGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      snareModel: snareModel ?? this.snareModel,
      snareBody: snareBody ?? this.snareBody,
      snareRing: snareRing ?? this.snareRing,
      snareTune: snareTune ?? this.snareTune,
      snareSnares: snareSnares ?? this.snareSnares,
      snareSnap: snareSnap ?? this.snareSnap,
      snareDecay: snareDecay ?? this.snareDecay,
      snareVelocity: snareVelocity ?? this.snareVelocity,
    );
  }

  @override
  SnareGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'snareModel' => copyWith(snareModel: value.clamp(0.0, 1.0)),
      'snareBody' => copyWith(snareBody: value.clamp(0.0, 1.0)),
      'snareRing' => copyWith(snareRing: value.clamp(0.0, 1.0)),
      'snareTune' => copyWith(snareTune: value.clamp(0.0, 1.0)),
      'snareSnares' => copyWith(snareSnares: value.clamp(0.0, 1.0)),
      'snareSnap' => copyWith(snareSnap: value.clamp(0.0, 1.0)),
      'snareDecay' => copyWith(snareDecay: value.clamp(0.0, 1.0)),
      'snareVelocity' => copyWith(snareVelocity: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class ClapGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const ClapGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.clapBursts,
    required this.clapSpread,
    required this.clapTone,
    required this.clapRoom,
    required this.clapDecay,
    required this.clapVelocity,
  }) : super(type: 'clap_generator');

  final double clapBursts;
  final double clapSpread;
  final double clapTone;
  final double clapRoom;
  final double clapDecay;
  final double clapVelocity;

  factory ClapGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ClapGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      clapBursts: (params['clapBursts'] as num?)?.toDouble() ?? 0.50,
      clapSpread: (params['clapSpread'] as num?)?.toDouble() ?? 0.45,
      clapTone: (params['clapTone'] as num?)?.toDouble() ?? 0.55,
      clapRoom: (params['clapRoom'] as num?)?.toDouble() ?? 0.50,
      clapDecay: (params['clapDecay'] as num?)?.toDouble() ?? 0.50,
      clapVelocity: (params['clapVelocity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  ClapGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? clapBursts,
    double? clapSpread,
    double? clapTone,
    double? clapRoom,
    double? clapDecay,
    double? clapVelocity,
  }) {
    return ClapGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      clapBursts: clapBursts ?? this.clapBursts,
      clapSpread: clapSpread ?? this.clapSpread,
      clapTone: clapTone ?? this.clapTone,
      clapRoom: clapRoom ?? this.clapRoom,
      clapDecay: clapDecay ?? this.clapDecay,
      clapVelocity: clapVelocity ?? this.clapVelocity,
    );
  }

  @override
  ClapGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'clapBursts' => copyWith(clapBursts: value.clamp(0.0, 1.0)),
      'clapSpread' => copyWith(clapSpread: value.clamp(0.0, 1.0)),
      'clapTone' => copyWith(clapTone: value.clamp(0.0, 1.0)),
      'clapRoom' => copyWith(clapRoom: value.clamp(0.0, 1.0)),
      'clapDecay' => copyWith(clapDecay: value.clamp(0.0, 1.0)),
      'clapVelocity' => copyWith(clapVelocity: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class CymbalGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const CymbalGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.cymbalModel,
    required this.cymbalColor,
    required this.cymbalDecay,
    required this.cymbalVelocity,
    required this.cymbalWidth,
  }) : super(type: 'cymbal_generator');

  final double cymbalModel;
  final double cymbalColor;
  final double cymbalDecay;
  final double cymbalVelocity;
  final double cymbalWidth;

  factory CymbalGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return CymbalGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      cymbalModel: (params['cymbalModel'] as num?)?.toDouble() ?? 0.0,
      cymbalColor: readCymbalColor(params),
      cymbalDecay: (params['cymbalDecay'] as num?)?.toDouble() ?? 0.50,
      cymbalVelocity: (params['cymbalVelocity'] as num?)?.toDouble() ?? 1.0,
      cymbalWidth: (params['cymbalWidth'] as num?)?.toDouble() ?? 0.35,
    );
  }

  @override
  CymbalGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? cymbalModel,
    double? cymbalColor,
    double? cymbalDecay,
    double? cymbalVelocity,
    double? cymbalWidth,
  }) {
    return CymbalGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      cymbalModel: cymbalModel ?? this.cymbalModel,
      cymbalColor: cymbalColor ?? this.cymbalColor,
      cymbalDecay: cymbalDecay ?? this.cymbalDecay,
      cymbalVelocity: cymbalVelocity ?? this.cymbalVelocity,
      cymbalWidth: cymbalWidth ?? this.cymbalWidth,
    );
  }

  @override
  CymbalGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'cymbalModel' => copyWith(cymbalModel: value.clamp(0.0, 1.0)),
      'cymbalColor' => copyWith(cymbalColor: value.clamp(0.0, 1.0)),
      'cymbalDecay' => copyWith(cymbalDecay: value.clamp(0.0, 1.0)),
      'cymbalVelocity' => copyWith(cymbalVelocity: value.clamp(0.0, 1.0)),
      'cymbalWidth' => copyWith(cymbalWidth: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class CrashGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const CrashGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.crashModel,
    required this.crashColor,
    required this.crashSpread,
    required this.crashDecay,
    required this.crashVelocity,
  }) : super(type: 'crash_generator');

  final double crashModel;
  final double crashColor;
  final double crashSpread;
  final double crashDecay;
  final double crashVelocity;

  factory CrashGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return CrashGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      crashModel: (params['crashModel'] as num?)?.toDouble() ?? 0.0,
      crashColor: readCrashColor(params),
      crashSpread: (params['crashSpread'] as num?)?.toDouble() ?? 0.50,
      crashDecay: (params['crashDecay'] as num?)?.toDouble() ?? 0.55,
      crashVelocity: (params['crashVelocity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  CrashGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? crashModel,
    double? crashColor,
    double? crashSpread,
    double? crashDecay,
    double? crashVelocity,
  }) {
    return CrashGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      crashModel: crashModel ?? this.crashModel,
      crashColor: crashColor ?? this.crashColor,
      crashSpread: crashSpread ?? this.crashSpread,
      crashDecay: crashDecay ?? this.crashDecay,
      crashVelocity: crashVelocity ?? this.crashVelocity,
    );
  }

  @override
  CrashGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'crashModel' => copyWith(crashModel: value.clamp(0.0, 1.0)),
      'crashColor' => copyWith(crashColor: value.clamp(0.0, 1.0)),
      'crashSpread' => copyWith(crashSpread: value.clamp(0.0, 1.0)),
      'crashDecay' => copyWith(crashDecay: value.clamp(0.0, 1.0)),
      'crashVelocity' => copyWith(crashVelocity: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}