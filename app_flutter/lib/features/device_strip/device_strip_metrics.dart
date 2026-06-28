import 'bass_synth_device_panel.dart';
import 'clap_generator_device_panel.dart';
import 'crash_generator_device_panel.dart';
import 'cymbal_generator_device_panel.dart';
import 'device_knob_sizes.dart';
import 'dynamics_fx_panels.dart';
import 'frequency_fx_panels.dart';
import 'resonator_bank_panel.dart';
import 'routing_device_panel.dart';
import 'kick_generator_device_panel.dart';
import 'oscillator_device_panel.dart';
import 'phase_mod_synth_device_panel.dart';
import 'sampler_device_panel.dart';
import 'snare_generator_device_panel.dart';
import 'subtractive_synth_device_panel.dart';
import 'wavetable_synth_device_panel.dart';
import 'time_fx_panels.dart';
import 'mood_fx_panels.dart';

/// Device strip layout constants.
class DeviceStripMetrics {
  const DeviceStripMetrics._();

  static const _dynamicsTypes = {'gate', 'compressor', 'expander', 'limiter'};
  static const _timeFxTypes = {'delay', 'reverb', 'chorus', 'phaser'};
  static const _moodFxTypes = {'bitcrusher', 'distortion', 'tremolo'};
  static const _frequencyFxTypes = {
    'filter', 'four_band_eq', 'frequency_shifter', 'resonator_bank',
  };
  static const _drumTypes = {
    'kick_generator',
    'snare_generator',
    'clap_generator',
    'cymbal_generator',
    'crash_generator',
  };
  static const _routingTypes = {'audio_receiver', 'midi_receiver'};

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
      4 * eqFxBandColumnWidth +
      3 * eqFxBandColumnGap +
      eqFxPanelPaddingH;

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

  /// Dynamics FX input column (meter).
  static const double dynamicsInputPanelWidth = 64;
  static const double routingOutputPanelWidth = 34;

  static double inputPanelWidthFor(String deviceType) =>
      _dynamicsTypes.contains(deviceType) ||
      _timeFxTypes.contains(deviceType) ||
      _frequencyFxTypes.contains(deviceType)
          ? dynamicsInputPanelWidth
          : 0;

  static double outputPanelWidthFor(String deviceType) {
    if (_routingTypes.contains(deviceType)) return routingOutputPanelWidth;
    if (_drumTypes.contains(deviceType)) return drumMonoOutputPanelWidth;
    if (_dynamicsTypes.contains(deviceType)) return dynamicsOutputPanelWidth;
    if (_timeFxTypes.contains(deviceType)) return dynamicsOutputPanelWidth;
    if (_moodFxTypes.contains(deviceType)) return dynamicsOutputPanelWidth;
    if (_frequencyFxTypes.contains(deviceType)) return dynamicsOutputPanelWidth;
    return stereoOutputPanelWidth;
  }

  static double designWidthFor(String deviceType, {bool collapsed = false}) {
    if (collapsed) {
      return collapsedDesignWidth;
    }
    return switch (deviceType) {
      'simple_sampler' => SamplerDevicePanel.designWidth,
      'bass_synth' => BassSynthDevicePanel.designWidth,
      'subtractive_synth' => SubtractiveSynthDevicePanel.designWidth,
      'kick_generator' => KickGeneratorDevicePanel.designWidth,
      'snare_generator' => SnareGeneratorDevicePanel.designWidth,
      'clap_generator' => ClapGeneratorDevicePanel.designWidth,
      'cymbal_generator' => CymbalGeneratorDevicePanel.designWidth,
      'crash_generator' => CrashGeneratorDevicePanel.designWidth,
      'gate' => GateDevicePanel.designWidth,
      'compressor' => CompressorDevicePanel.designWidth,
      'expander' => ExpanderDevicePanel.designWidth,
      'limiter' => LimiterDevicePanel.designWidth,
      'delay' => DelayFxPanel.designWidth,
      'reverb' => ReverbFxPanel.designWidth,
      'chorus' => ChorusFxPanel.designWidth,
      'phaser' => PhaserFxPanel.designWidth,
      'filter' => FilterDevicePanel.designWidth,
      'four_band_eq' => FourBandEqDevicePanel.designWidth,
      'frequency_shifter' => FreqShifterDevicePanel.designWidth,
      'resonator_bank' => ResonatorBankPanel.designWidth,
      'audio_receiver' || 'midi_receiver' => RoutingDevicePanel.designWidth,
      'bitcrusher' => BitcrusherFxPanel.designWidth,
      'distortion' => DistortionFxPanel.designWidth,
      'tremolo' => TremoloFxPanel.designWidth,
      'wavetable_synth' => WavetableSynthDevicePanel.designWidth,
      'simple_oscillator' => OscillatorDevicePanel.designWidth,
      'phase_mod_synth' => PhaseModSynthDevicePanel.designWidth,
      _ => 280,
    };
  }
}
