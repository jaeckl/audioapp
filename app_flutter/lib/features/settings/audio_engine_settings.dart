enum AudioEngineProfile { lowLatency, balanced, safe, custom }

extension AudioEngineProfileDetails on AudioEngineProfile {
  String get storageValue => switch (this) {
        AudioEngineProfile.lowLatency => 'low_latency',
        AudioEngineProfile.balanced => 'balanced',
        AudioEngineProfile.safe => 'safe',
        AudioEngineProfile.custom => 'custom',
      };

  String get label => switch (this) {
        AudioEngineProfile.lowLatency => 'Low latency',
        AudioEngineProfile.balanced => 'Balanced',
        AudioEngineProfile.safe => 'Safe',
        AudioEngineProfile.custom => 'Custom',
      };

  String get description => switch (this) {
        AudioEngineProfile.lowLatency =>
          'Fastest response; may need more CPU on demanding projects',
        AudioEngineProfile.balanced =>
          'Responsive playback with additional stability headroom',
        AudioEngineProfile.safe =>
          'Largest buffer for projects that cannot play cleanly',
        AudioEngineProfile.custom =>
          'Set sample rate, callback, buffer and stream policy directly',
      };

  static AudioEngineProfile fromStorage(String? value) => switch (value) {
        'low_latency' => AudioEngineProfile.lowLatency,
        'safe' => AudioEngineProfile.safe,
        'custom' => AudioEngineProfile.custom,
        _ => AudioEngineProfile.balanced,
      };
}

class AudioEngineCustomSettings {
  const AudioEngineCustomSettings({
    this.sampleRate = 48000,
    this.framesPerCallback = 192,
    this.bufferCapacityFrames = 2048,
    this.bufferSizeFrames = 768,
    this.lowLatency = true,
    this.exclusive = false,
  });

  final int sampleRate;
  final int framesPerCallback;
  final int bufferCapacityFrames;
  final int bufferSizeFrames;
  final bool lowLatency;
  final bool exclusive;

  Map<String, dynamic> toMap() => {
        'sampleRate': sampleRate,
        'framesPerCallback': framesPerCallback,
        'bufferCapacityFrames': bufferCapacityFrames,
        'bufferSizeFrames': bufferSizeFrames,
        'lowLatency': lowLatency,
        'exclusive': exclusive,
      };

  void validate() {
    if (sampleRate < 8000 || sampleRate > 192000) {
      throw const FormatException('Sample rate must be 8000–192000 Hz.');
    }
    if (framesPerCallback < 16 || framesPerCallback > 4096) {
      throw const FormatException('Callback size must be 16–4096 frames.');
    }
    if (bufferCapacityFrames < 64 || bufferCapacityFrames > 32768) {
      throw const FormatException('Buffer capacity must be 64–32768 frames.');
    }
    if (bufferSizeFrames < 16 || bufferSizeFrames > bufferCapacityFrames) {
      throw const FormatException(
        'Active buffer must fit inside the buffer capacity.',
      );
    }
  }
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
    required this.requestedSampleRate,
    required this.requestedFramesPerCallback,
    required this.requestedBufferCapacityFrames,
    required this.requestedBufferSizeFrames,
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
      requestedSampleRate: integer('requestedSampleRate'),
      requestedFramesPerCallback: integer('requestedFramesPerCallback'),
      requestedBufferCapacityFrames: integer('requestedBufferCapacityFrames'),
      requestedBufferSizeFrames: integer('requestedBufferSizeFrames'),
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
  final int requestedSampleRate;
  final int requestedFramesPerCallback;
  final int requestedBufferCapacityFrames;
  final int requestedBufferSizeFrames;
}
