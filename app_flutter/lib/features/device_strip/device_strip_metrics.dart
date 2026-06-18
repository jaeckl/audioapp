/// Device strip layout constants.
class DeviceStripMetrics {
  const DeviceStripMetrics._();

  /// Canonical sampler strip width (landscape does not stretch beyond this).
  static const double designWidth = 520;

  /// Expanded strip + fullscreen chain device row height.
  static const double height = 320;

  /// Collapsed strip: header-only device name panels.
  static const double collapsedHeight = 64;

  /// Minimap scrub bar under the fullscreen chain.
  static const double minimapHeight = 48;

  /// Width of each device panel in the horizontal chain.
  static const double slotWidth = designWidth;

  /// Narrow column between devices (VU + insert).
  static const double separatorWidth = 44;

  static const double insertButtonSize = 28;

  /// Alias for [height] — fullscreen chain uses the same device card height.
  static const double fullscreenHeight = height;

  static const double oscillatorDesignWidth = 360;

  static const double collapsedDesignWidth = 160;

  /// Tool rail prepended to expanded/fullscreen device cards.
  static const double toolRailWidth = 30;

  /// Gain + pan panel between tool rail and device card.
  static const double levelPanelWidth = 64;

  static double designWidthFor(String deviceType, {bool collapsed = false}) {
    if (collapsed) {
      return collapsedDesignWidth;
    }
    return switch (deviceType) {
      'simple_sampler' => designWidth,
      'subtractive_synth' => oscillatorDesignWidth,
      'kick_generator' => oscillatorDesignWidth,
      'snare_generator' => oscillatorDesignWidth,
      'clap_generator' => oscillatorDesignWidth,
      'cymbal_generator' => oscillatorDesignWidth,
      'simple_oscillator' => oscillatorDesignWidth,
      _ => 280,
    };
  }
}
