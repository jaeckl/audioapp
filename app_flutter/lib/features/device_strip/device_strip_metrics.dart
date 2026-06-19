import 'device_knob_sizes.dart';

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

  /// Canonical sampler strip width (~⅔ of the original 520).
  static const double samplerDesignWidth = 348;

  /// Default viewport reference width (legacy alias; sampler uses [samplerDesignWidth]).
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

  /// Subtractive synth: three-tab layout (Osc · Mix · Tone) needs filter+amp in one row.
  static const double subtractiveSynthDesignWidth = 500;

  /// Dynamics FX knob grid — panel width shrink-wraps to this.
  static const double dynamicsFxKnobSize = DeviceKnobSizes.strip;
  static const double dynamicsFxKnobGap = 8;
  static const double dynamicsFxKnobColumnWidth = 62;
  static const double dynamicsFxPanelPaddingH = 12;

  static double get dynamicsFxKnobGridWidth =>
      3 * dynamicsFxKnobColumnWidth + 2 * dynamicsFxKnobGap;

  /// Compact dynamics FX card (2-row knob grid + preview).
  static double get dynamicsFxDesignWidth =>
      dynamicsFxKnobGridWidth + dynamicsFxPanelPaddingH;

  static const double collapsedDesignWidth = 160;

  /// Tool rail prepended to expanded/fullscreen device cards.
  static const double toolRailWidth = 30;

  /// Gain + pan panel between tool rail and device card (legacy name).
  static const double levelPanelWidth = stereoOutputPanelWidth;

  /// Stereo instrument output column (pan + gain).
  static const double stereoOutputPanelWidth = 64;

  /// Mono drum output column (gain + velocity sens).
  static const double drumMonoOutputPanelWidth = 64;

  /// Dynamics FX output column (GR meter + gain) — matches [dynamicsInputPanelWidth].
  static const double dynamicsOutputPanelWidth = dynamicsInputPanelWidth;

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
      'simple_sampler' => samplerDesignWidth,
      'subtractive_synth' => subtractiveSynthDesignWidth,
      'kick_generator' => kickDesignWidth,
      'snare_generator' => kickDesignWidth,
      'clap_generator' => oscillatorDesignWidth,
      'cymbal_generator' => kickDesignWidth,
      'crash_generator' => kickDesignWidth,
      'gate' => dynamicsFxDesignWidth,
      'compressor' => dynamicsFxDesignWidth,
      'expander' => dynamicsFxDesignWidth,
      'limiter' => dynamicsFxDesignWidth,
      'simple_oscillator' => oscillatorDesignWidth,
      _ => 280,
    };
  }
}
