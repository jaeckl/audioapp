enum AudioEngineProfile { lowLatency, balanced, safe }

extension AudioEngineProfileDetails on AudioEngineProfile {
  String get storageValue => switch (this) {
        AudioEngineProfile.lowLatency => 'low_latency',
        AudioEngineProfile.balanced => 'balanced',
        AudioEngineProfile.safe => 'safe',
      };

  String get label => switch (this) {
        AudioEngineProfile.lowLatency => 'Low latency',
        AudioEngineProfile.balanced => 'Balanced',
        AudioEngineProfile.safe => 'Safe',
      };

  String get description => switch (this) {
        AudioEngineProfile.lowLatency =>
          'Fastest response; may need more CPU on demanding projects',
        AudioEngineProfile.balanced =>
          'Responsive playback with additional stability headroom',
        AudioEngineProfile.safe =>
          'Largest buffer for projects that cannot play cleanly',
      };

  static AudioEngineProfile fromStorage(String? value) => switch (value) {
        'low_latency' => AudioEngineProfile.lowLatency,
        'safe' => AudioEngineProfile.safe,
        _ => AudioEngineProfile.balanced,
      };
}

class AudioEngineStatus {
  const AudioEngineStatus({
    required this.profile,
    required this.platform,
    required this.streamOpen,
    required this.sampleRate,
    required this.framesPerBurst,
    required this.bufferSizeFrames,
    required this.bufferCapacityFrames,
    required this.framesPerCallback,
    required this.xRunCount,
    required this.callbackOverruns,
    required this.maxCallbackMicros,
    required this.sharingMode,
    required this.performanceMode,
  });

  factory AudioEngineStatus.fromMap(Map<dynamic, dynamic> map) {
    int integer(String key) => (map[key] as num?)?.toInt() ?? 0;
    double decimal(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return AudioEngineStatus(
      profile:
          AudioEngineProfileDetails.fromStorage(map['profile']?.toString()),
      platform: map['platform']?.toString() ?? 'Audio engine',
      streamOpen: map['streamOpen'] == true,
      sampleRate: decimal('sampleRate'),
      framesPerBurst: integer('framesPerBurst'),
      bufferSizeFrames: integer('bufferSizeFrames'),
      bufferCapacityFrames: integer('bufferCapacityFrames'),
      framesPerCallback: integer('framesPerCallback'),
      xRunCount: integer('xRunCount'),
      callbackOverruns: integer('callbackOverruns'),
      maxCallbackMicros: decimal('maxCallbackMicros'),
      sharingMode: map['sharingMode']?.toString() ?? 'unknown',
      performanceMode: map['performanceMode']?.toString() ?? 'unknown',
    );
  }

  final AudioEngineProfile profile;
  final String platform;
  final bool streamOpen;
  final double sampleRate;
  final int framesPerBurst;
  final int bufferSizeFrames;
  final int bufferCapacityFrames;
  final int framesPerCallback;
  final int xRunCount;
  final int callbackOverruns;
  final double maxCallbackMicros;
  final String sharingMode;
  final String performanceMode;
}
