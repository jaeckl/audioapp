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
  static const sampleRateChoices = [44100, 48000, 88200, 96000, 192000];
  static const callbackFrameChoices = [512, 1024, 2048, 4096];
  static const bufferCapacityChoices = [2048, 4096, 8192, 16384, 32768];
  static const bufferSizeChoices = [1024, 2048, 4096, 8192, 16384, 32768];

  const AudioEngineCustomSettings({
    this.sampleRate = 48000,
    this.framesPerCallback = 1024,
    this.bufferCapacityFrames = 8192,
    this.bufferSizeFrames = 8192,
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
    if (!sampleRateChoices.contains(sampleRate)) {
      throw const FormatException('Choose a supported sample rate.');
    }
    if (!callbackFrameChoices.contains(framesPerCallback)) {
      throw const FormatException('Choose a supported callback size.');
    }
    if (!bufferCapacityChoices.contains(bufferCapacityFrames)) {
      throw const FormatException('Choose a supported buffer capacity.');
    }
    if (!bufferSizeChoices.contains(bufferSizeFrames) ||
        bufferSizeFrames > bufferCapacityFrames) {
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
