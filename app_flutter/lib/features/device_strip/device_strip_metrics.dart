/// Device strip layout constants.
class DeviceStripMetrics {
  const DeviceStripMetrics._();

  /// Canonical sampler strip width (landscape does not stretch beyond this).
  static const double designWidth = 520;

  /// Expanded sampler strip: tabs + big knobs.
  static const double height = 236;

  /// Collapsed peek height (waveform + expand).
  static const double collapsedHeight = 112;
}
