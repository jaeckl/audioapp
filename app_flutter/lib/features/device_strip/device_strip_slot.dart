import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/param_descriptor.dart';
import '../../bridge/live_meters_dto.dart';
import '../../bridge/project_snapshot.dart';
import '../content_library/library_filter.dart';
import 'bass_synth_device_panel.dart';
import 'bass_synth_device_strip.dart';
import 'device_container_tabs.dart';
import 'device_modulator_scope.dart';
import 'device_strip_chrome.dart';
import 'device_tab_bar.dart';
import 'device_strip_card.dart';
import 'device_strip_device_kind.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'device_strip_viewport.dart';
import 'device_tool_rail.dart';
import 'device_drag_data.dart';
import 'modulation_grid.dart';
import 'lfo_properties_panel.dart';
import 'envelope_properties_panel.dart';
import 'random_properties_panel.dart';
import 'curve_properties_panel.dart';
import 'curve_editor_screen.dart';
import 'sequencer_step_editor.dart';
import 'generic_param_editor.dart';
import 'modulator_types.dart';
import 'device_knob_sizes.dart';
import 'effective_parameter_binding.dart';
import 'modulator_rate_codec.dart';
import 'rotary_knob.dart';
import 'kick_generator_device_strip.dart';
import 'kick_model.dart';
import 'snare_generator_device_strip.dart';
import 'clap_generator_device_panel.dart';
import 'clap_generator_device_strip.dart';
import 'dedicated_percussion_device_panel.dart';
import 'crash_generator_device_strip.dart';
import 'crash_model.dart';
import 'dynamics_fx_panels.dart';
import 'time_fx_panels.dart';
import 'drum_machine_device_panel.dart';
import 'modulation_connect_mode.dart';
import 'chain_device_panel.dart';
import 'split_device_panel.dart';
import 'multiband_split_panel.dart';
import 'spectral_loud_split_panel.dart';
import 'granular_device_panel.dart';
import 'mood_fx_panels.dart';
import 'restore_fx_panels.dart';
import 'utility_device_panel.dart';
import 'frequency_fx_panels.dart';
import 'resonator_bank_panel.dart';
import 'routing_device_panel.dart';
import 'midi_delay_panel.dart';
import 'oscillator_device_panel.dart';
import 'sampler_device_panel.dart';
import 'phase_mod_synth_device_panel.dart';
import 'phase_mod_synth_device_strip.dart';
import 'sampler_device_strip.dart';
import 'subtractive_synth_device_panel.dart';
import 'subtractive_synth_device_strip.dart';
import 'wavetable_synth_device_panel.dart';
import 'wavetable_synth_device_strip.dart';
import 'analysis_device_panel.dart';

part 'device_strip_slot_device_strip_slot_density.dart';
part 'device_strip_slot_private_device_strip_slot_state.dart';
part 'device_strip_slot_private_unknown_device_body.dart';

part 'device_strip_slot_private_device_strip_slot_state_sync_global_connect_mode.dart';
part 'device_strip_slot_private_device_strip_slot_state_ensure_param_descriptors.dart';
part 'device_strip_slot_private_device_strip_slot_state_on_bridge_call.dart';
part 'device_strip_slot_private_device_strip_slot_state_on_modulation_for.dart';
part 'device_strip_slot_private_device_strip_slot_state_function.dart';
part 'device_strip_slot_private_device_strip_slot_state_on_automation_link_tap.dart';
part 'device_strip_slot_private_device_strip_slot_state_on_automate_parameter.dart';
part 'device_strip_slot_private_device_strip_slot_state_on_bypass_modulation_assign.dart';
part 'device_strip_slot_private_device_strip_slot_state_initial_tab_index.dart';
part 'device_strip_slot_private_device_strip_slot_state_on_tab_selected.dart';
part 'device_strip_slot_private_device_strip_slot_state_on_lfo_tap.dart';
part 'device_strip_slot_private_device_strip_slot_state_on_lfo_long_press.dart';
part 'device_strip_slot_private_device_strip_slot_state_chrome_bindings.dart';
part 'device_strip_slot_private_device_strip_slot_state_meter_aware_chrome_panel.dart';
part 'device_strip_slot_private_device_strip_slot_state_modulation_sidebar.dart';
part 'device_strip_slot_private_device_strip_slot_state_targets_panel.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_modulator_properties_panel.dart';
part 'device_strip_slot_private_device_strip_slot_state_seq_header.dart';
part 'device_strip_slot_private_device_strip_slot_state_seq_retrigger_bar.dart';
part 'device_strip_slot_private_device_strip_slot_state_seq_sync_divisions.dart';
part 'device_strip_slot_private_device_strip_slot_state_seq_knobs.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_content.dart';
part 'device_strip_slot_private_device_strip_slot_state_seq_polarity_toggle.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_oscilloscope_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_drum_machine_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_device_chain_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_split_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_multiband_split_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_spectral_loud_split_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_granular_formant_synth_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_simple_sampler_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_simple_oscillator_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_bass_synth_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_phase_mod_synth_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_wavetable_synth_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_subtractive_synth_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_kick_generator_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_snare_generator_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_clap_generator_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_dedicated_percussion_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_crash_generator_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_gate_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_compressor_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_expander_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_limiter_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_ducker_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_utility_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_filter_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_four_band_eq_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_frequency_shifter_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_resonator_bank_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_audio_receiver_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_midi_delay_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_delay_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_reverb_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_chorus_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_phaser_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_bitcrusher_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_distortion_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_tremolo_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_stutter_fx_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_dc_offset_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_de_crackler_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_de_esser_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_de_hum_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_de_noise_device.dart';
part 'device_strip_slot_private_device_strip_slot_state_build_device_build_unknown_device.dart';

const _seqAccent = Color(0xFFE8A54B);
const _seqSyncLabels = ['1/1', '1/2', '1/4', '1/8', '1/16'];
const _targetsPanelWidth = 160.0;
final Map<String, List<DeviceParamDescriptor>> _paramCache = {};

/// One device panel in the horizontal chain.
class DeviceStripSlot extends StatefulWidget {
  const DeviceStripSlot({
    super.key,
    required this.track,
    this.routingSources = const [],
    this.routingTracks = const [],
    required this.device,
    required this.sample,
    required this.bpm,
    this.playheadBeat = 0,
    this.playheadBeatListenable,
    this.liveMetersListenable,
    required this.playing,
    required this.density,
    required this.onSamplerParameterChanged,
    required this.onDeviceParameterChanged,
    this.onDeviceStringParameterChanged,
    required this.onOpenSamplerEditor,
    required this.onFrequencyChanged,
    this.onSamplerTabChanged,
    this.onSynthTabChanged,
    this.onBassTabChanged,
    this.onCollapse,
    this.onBypassToggle,
    this.onDeleteRequest,
    this.onOpenLibrary,
    this.onPreviewSample,
    this.onPreviewSampler,
    this.samplerTab = SamplerDeviceTab.wave,
    this.synthTab = SubtractiveDeviceTab.osc,
    this.bassTab = BassSynthDeviceTab.tone,
    this.onWtTabChanged,
    this.wtTab = WavetableSynthDeviceTab.osc,
    this.onPmTabChanged,
    this.pmTab = PhaseModSynthDeviceTab.mix,
    this.lfos = const [],
    this.modEdges = const [],
    this.onModulationBridgeCall,
    this.automationLinkActive = false,
    this.automationLinkClipId,
    this.projectAutomationClips = const [],
    this.onAutomationParamSelected,
    this.onAutomateParameter,
    this.onGetParamDescriptors,
    this.drumSelectedNote = 36,
    this.drumBankStart = 36,
    this.drumChainExpanded = true,
    this.onDrumPadSelected,
    this.onDrumBankChanged,
    this.onDrumChainToggle,
    this.onDrumTriggerNote,
    this.onEmptyDrumPadTap,
    this.audioFxExpanded = false,
    this.noteFxExpanded = false,
    this.onToggleAudioFx,
    this.onToggleNoteFx,
    this.splitBranch0Expanded = false,
    this.splitBranch1Expanded = false,
    this.onToggleSplitBranch,
    this.multibandExpandedBands = const {},
    this.onToggleMultibandBand,
    this.spectralLoudExpandedBands = const {},
    this.onToggleSpectralLoudBand,
    this.reorderDragData,
  });

  final TrackSnapshot track;
  final List<RoutingSourceOption> routingSources;
  final List<TrackSnapshot> routingTracks;
  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final int bpm;
  final double playheadBeat;
  final ValueListenable<double>? playheadBeatListenable;
  final ValueListenable<Map<String, DeviceMeterReading>>? liveMetersListenable;
  final bool playing;
  final DeviceStripSlotDensity density;
  final void Function(String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(String parameterId, double value)
      onDeviceParameterChanged;
  final void Function(String parameterId, String value)?
      onDeviceStringParameterChanged;
  final VoidCallback onOpenSamplerEditor;
  final void Function(double frequencyHz) onFrequencyChanged;
  final ValueChanged<SamplerDeviceTab>? onSamplerTabChanged;
  final ValueChanged<SubtractiveDeviceTab>? onSynthTabChanged;
  final ValueChanged<BassSynthDeviceTab>? onBassTabChanged;
  final VoidCallback? onCollapse;
  final VoidCallback? onBypassToggle;
  final VoidCallback? onDeleteRequest;
  final void Function(LibraryFilter filter)? onOpenLibrary;
  final ValueChanged<SampleLibraryEntrySnapshot>? onPreviewSample;
  final ValueChanged<int>? onPreviewSampler;
  final SamplerDeviceTab samplerTab;
  final SubtractiveDeviceTab synthTab;
  final BassSynthDeviceTab bassTab;
  final ValueChanged<WavetableSynthDeviceTab>? onWtTabChanged;
  final WavetableSynthDeviceTab wtTab;
  final ValueChanged<PhaseModSynthDeviceTab>? onPmTabChanged;
  final PhaseModSynthDeviceTab pmTab;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final Future<ProjectSnapshot> Function(
      String method, Map<String, dynamic> args)? onModulationBridgeCall;
  final bool automationLinkActive;
  final String? automationLinkClipId;
  final List<AutomationClipSnapshot> projectAutomationClips;
  final Future<bool> Function(String deviceId, String paramId)?
      onAutomationParamSelected;
  final void Function(String deviceId, String paramId)? onAutomateParameter;

  /// Optional: fetch param descriptors for the generic fallback editor.
  final Future<List<DeviceParamDescriptor>> Function(String deviceType)?
      onGetParamDescriptors;
  final int drumSelectedNote;
  final int drumBankStart;
  final bool drumChainExpanded;
  final ValueChanged<int>? onDrumPadSelected;
  final ValueChanged<int>? onDrumBankChanged;
  final VoidCallback? onDrumChainToggle;
  final ValueChanged<int>? onDrumTriggerNote;
  final ValueChanged<int>? onEmptyDrumPadTap;
  final bool audioFxExpanded;
  final bool noteFxExpanded;
  final VoidCallback? onToggleAudioFx;
  final VoidCallback? onToggleNoteFx;
  final bool splitBranch0Expanded;
  final bool splitBranch1Expanded;
  final void Function(int branchIndex)? onToggleSplitBranch;
  final Set<int> multibandExpandedBands;
  final void Function(int bandIndex)? onToggleMultibandBand;
  final Set<int> spectralLoudExpandedBands;
  final void Function(int bandIndex)? onToggleSpectralLoudBand;
  final DeviceDragData? reorderDragData;

  @override
  State<DeviceStripSlot> createState() => _DeviceStripSlotState();
}
