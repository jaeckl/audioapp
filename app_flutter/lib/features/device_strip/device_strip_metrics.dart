/// Device strip layout constants.
class DeviceStripMetrics {
  const DeviceStripMetrics._();

  /// Canonical sampler strip width (landscape does not stretch beyond this).
  static const double designWidth = 520;

  /// Expanded sampler strip: tabs + big knobs.
  static const double height = 236;

  /// Collapsed peek height (waveform + expand).
  static const double collapsedHeight = 112;

  /// Width of each device panel in the horizontal chain.
  static const double slotWidth = designWidth;

  /// Narrow column between devices (VU + insert).
  static const double separatorWidth = 44;

  static const double insertButtonSize = 28;

  /// Fullscreen chain uses taller panels.
  static const double fullscreenHeight = 320;

  static const double oscillatorDesignWidth = 360;

  static const double collapsedDesignWidth = 240;

  static double designWidthFor(String deviceType, {bool collapsed = false}) {
    if (collapsed) {
      return collapsedDesignWidth;
    }
    return switch (deviceType) {
      'simple_sampler' => designWidth,
      'simple_oscillator' => oscillatorDesignWidth,
      _ => 280,
    };
  }
}
