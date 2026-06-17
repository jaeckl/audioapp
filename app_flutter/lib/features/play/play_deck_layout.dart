/// Mode toggle for the rail (keyboard/pads switch).
enum PlaySurfaceMode { pads, keys }

/// What is currently filling the play area next to the rail.
enum PlayContextView { perform, octave, performPanel, scaleBuilder, performancePanel }

enum ArpMode {
  off,
  up,
  down,
  upDown,
  downUp,
  random,
  chord,
  strum,
}

extension ArpModeLabel on ArpMode {
  String get label => switch (this) {
        ArpMode.off => 'Off',
        ArpMode.up => 'Up',
        ArpMode.down => 'Down',
        ArpMode.upDown => 'Up–Down',
        ArpMode.downUp => 'Down–Up',
        ArpMode.random => 'Random',
        ArpMode.chord => 'Chord',
        ArpMode.strum => 'Strum',
      };
}

enum ChordQuality { off, major, minor, seventh, minor7, sus2, sus4 }

extension ChordQualityLabel on ChordQuality {
  String get label => switch (this) {
        ChordQuality.off => 'Off',
        ChordQuality.major => 'maj',
        ChordQuality.minor => 'min',
        ChordQuality.seventh => '7',
        ChordQuality.minor7 => 'm7',
        ChordQuality.sus2 => 'sus2',
        ChordQuality.sus4 => 'sus4',
      };

  List<int> get intervals => switch (this) {
        ChordQuality.off => const [0],
        ChordQuality.major => const [0, 4, 7],
        ChordQuality.minor => const [0, 3, 7],
        ChordQuality.seventh => const [0, 4, 7, 10],
        ChordQuality.minor7 => const [0, 3, 7, 10],
        ChordQuality.sus2 => const [0, 2, 7],
        ChordQuality.sus4 => const [0, 5, 7],
      };
}

enum CaptureQuantize { off, quarter, eighth, sixteenth }

extension CaptureQuantizeLabel on CaptureQuantize {
  String get label => switch (this) {
        CaptureQuantize.off => 'Off',
        CaptureQuantize.quarter => '1/4',
        CaptureQuantize.eighth => '1/8',
        CaptureQuantize.sixteenth => '1/16',
      };
}

class ChordMemory {
  ChordMemory({required this.label, required this.quality});
  final String label;
  final ChordQuality quality;
}

class PlayDeckLayout {
  const PlayDeckLayout._();

  static const double deckHeight = 280;
  static const double modStripHeight = 22;
  static const double keyCellMinSize = 40;
  static const int keyMaxColumns = 8;
  static const int defaultKeyboardRows = 2;

  static double get chromeHeight => deckHeight + modStripHeight;
}
