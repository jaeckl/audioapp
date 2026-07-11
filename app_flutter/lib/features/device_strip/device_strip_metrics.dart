import '../../devices/device_repository.dart';
import 'device_knob_sizes.dart';
import 'routing_device_panel.dart';
import 'midi_delay_panel.dart';
import 'analysis_device_panel.dart';
import 'chain_device_panel.dart';

/// Device strip layout constants.
class DeviceStripMetrics {
  const DeviceStripMetrics._();

  static const _routingTypes = {
    'audio_receiver',
    'midi_receiver',
    'midi_delay'
  };
  static const _analysisTypes = {
    'oscilloscope',
    'spectrum_analyzer',
    'loudness_meter',
    'stereo_imager',
    'device_chain',
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

  /// Bass synth: two-column tab layout (left 5/7 + right 2/7).
  static const double bassSynthDesignWidth = 440;

  /// Subtractive synth: three-tab layout (Osc · Mix · Tone) needs filter+amp in one row.
  static const double subtractiveSynthDesignWidth = 500;

  /// Phase mod synth: 3-tab layout (ALGO · OP · TONE).
  static const double phaseModSynthDesignWidth = 420;

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

  // ─── Frequency FX EQ — 4 columns × 3 rows of compact ValueDragBoxes ──
  // With box width ≈ 44 + column gap 6, the band grid is 4 * 44 + 3 * 6 = 194.
  // Plus padding on both sides we land ~206 — same as the dynamics FX card.
  static const double eqFxBandColumnWidth = 44;
  static const double eqFxBandColumnGap = 6;
  static const double eqFxPanelPaddingH = 12;

  static double get fourBandEqDesignWidth =>
      4 * eqFxBandColumnWidth + 3 * eqFxBandColumnGap + eqFxPanelPaddingH;

  // Ring Mod and Filter use the same compact dynamics-FX-sized card.
  // Not `const` because they reference the [dynamicsFxDesignWidth] getter.
  static double get filterDesignWidth => dynamicsFxDesignWidth;
  static double get freqShifterDesignWidth => dynamicsFxDesignWidth;

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

  /// Synth output column: gain/pan knobs + FX toggle buttons.
  static const double synthOutputPanelWidth = 85;

  /// Dynamics FX input column (meter).
  static const double dynamicsInputPanelWidth = 64;
  static const double routingOutputPanelWidth = 34;

  static double inputPanelWidthFor(String deviceType) {
    final definition = deviceDefinitionRepository.find(deviceType);
    if (definition != null) return definition.layout.inputPanelWidth;
    return 0;
  }

  static double outputPanelWidthFor(String deviceType) {
    final definition = deviceDefinitionRepository.find(deviceType);
    if (definition != null) return definition.layout.outputPanelWidth;
    if (deviceType == 'device_chain') return toolRailWidth;
    if (_analysisTypes.contains(deviceType)) return stereoOutputPanelWidth;
    if (_routingTypes.contains(deviceType)) return routingOutputPanelWidth;
    return stereoOutputPanelWidth;
  }

  static double designWidthFor(String deviceType, {bool collapsed = false}) {
    if (collapsed) {
      return collapsedDesignWidth;
    }
    final definition = deviceDefinitionRepository.find(deviceType);
    if (definition != null) return definition.layout.designWidth;
    return switch (deviceType) {
      'audio_receiver' || 'midi_receiver' => RoutingDevicePanel.designWidth,
      'midi_delay' => MidiDelayPanel.designWidth,
      'device_chain' => ChainDevicePanel.designWidth,
      'oscilloscope' ||
      'spectrum_analyzer' ||
      'loudness_meter' ||
      'stereo_imager' =>
        AnalysisDevicePanel.designWidth,
      _ => 280,
    };
  }
}
