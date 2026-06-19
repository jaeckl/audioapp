/// Device strip layout constants.
class DeviceStripMetrics {
  const DeviceStripMetrics._();

  static const _dynamicsTypes = {'gate', 'compressor', 'expander', 'limiter'};
  static const _drumTypes = {
    'kick_generator',
    'snare_generator',
    'clap_generator',
    'cymbal_generator',
    'crash_generator',
  };

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

  static const double kickDesignWidth = 480;

  static const double oscillatorDesignWidth = 360;

  static const double collapsedDesignWidth = 160;

  /// Tool rail prepended to expanded/fullscreen device cards.
  static const double toolRailWidth = 30;

  /// Gain + pan panel between tool rail and device card (legacy name).
  static const double levelPanelWidth = stereoOutputPanelWidth;

  /// Stereo instrument output column (pan + gain).
  static const double stereoOutputPanelWidth = 64;

  /// Mono drum output column (gain + velocity sens).
  static const double drumMonoOutputPanelWidth = 64;

  /// Dynamics FX output column (gain + GR).
  static const double dynamicsOutputPanelWidth = 72;

  /// Dynamics FX input column (meter).
  static const double dynamicsInputPanelWidth = 64;

  static double inputPanelWidthFor(String deviceType) =>
      _dynamicsTypes.contains(deviceType) ? dynamicsInputPanelWidth : 0;

  static double outputPanelWidthFor(String deviceType) {
    if (_drumTypes.contains(deviceType)) return drumMonoOutputPanelWidth;
    if (_dynamicsTypes.contains(deviceType)) return dynamicsOutputPanelWidth;
    return stereoOutputPanelWidth;
  }

  static double designWidthFor(String deviceType, {bool collapsed = false}) {
    if (collapsed) {
      return collapsedDesignWidth;
    }
    return switch (deviceType) {
      'simple_sampler' => designWidth,
      'subtractive_synth' => oscillatorDesignWidth,
      'kick_generator' => kickDesignWidth,
      'snare_generator' => kickDesignWidth,
      'clap_generator' => oscillatorDesignWidth,
      'cymbal_generator' => kickDesignWidth,
      'crash_generator' => kickDesignWidth,
      'gate' => oscillatorDesignWidth,
      'compressor' => oscillatorDesignWidth,
      'expander' => oscillatorDesignWidth,
      'limiter' => oscillatorDesignWidth,
      'simple_oscillator' => oscillatorDesignWidth,
      _ => 280,
    };
  }
}
