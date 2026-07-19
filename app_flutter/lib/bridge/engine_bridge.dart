import 'dart:async';

import 'package:flutter/services.dart';

import 'delta_parser.dart';
import 'live_meters_dto.dart';
import 'param_descriptor.dart';
import 'project_snapshot.dart';
import 'transport_state.dart';
import '../features/settings/audio_engine_settings.dart';

part 'engine_bridge_recent_project_entry.dart';
part 'engine_bridge_audio_recording_session.dart';
part 'engine_bridge_live_midi_note_event.dart';
part 'engine_bridge_set_meter_subscriptions.dart';
part 'engine_bridge_graph_taps.dart';
part 'engine_bridge_ping.dart';
part 'engine_bridge_play.dart';
part 'engine_bridge_stop.dart';
part 'engine_bridge_audio_engine.dart';
part 'engine_bridge_create_project.dart';
part 'engine_bridge_get_project_snapshot.dart';
part 'engine_bridge_get_transport_state.dart';
part 'engine_bridge_add_track.dart';
part 'engine_bridge_add_group_track.dart';
part 'engine_bridge_set_track_group.dart';
part 'engine_bridge_move_track.dart';
part 'engine_bridge_set_track_muted.dart';
part 'engine_bridge_set_track_soloed.dart';
part 'engine_bridge_freeze_track.dart';
part 'engine_bridge_unfreeze_track.dart';
part 'engine_bridge_refresh_track_freeze.dart';
part 'engine_bridge_select_track.dart';
part 'engine_bridge_add_device_to_track.dart';
part 'engine_bridge_remove_device_from_track.dart';
part 'engine_bridge_add_device_to_drum_pad.dart';
part 'engine_bridge_remove_device_from_drum_pad.dart';
part 'engine_bridge_add_device_to_chain.dart';
part 'engine_bridge_remove_device_from_chain.dart';
part 'engine_bridge_add_device_to_split_branch.dart';
part 'engine_bridge_remove_device_from_split_branch.dart';
part 'engine_bridge_add_device_to_multiband_band.dart';
part 'engine_bridge_remove_device_from_multiband_band.dart';
part 'engine_bridge_add_device_to_spectral_loud_band.dart';
part 'engine_bridge_remove_device_from_spectral_loud_band.dart';
part 'engine_bridge_add_device_to_spectral_loud_pre_fx.dart';
part 'engine_bridge_remove_device_from_spectral_loud_pre_fx.dart';
part 'engine_bridge_add_device_to_spectral_loud_post_fx.dart';
part 'engine_bridge_remove_device_from_spectral_loud_post_fx.dart';
part 'engine_bridge_add_device_to_synth_audio_fx.dart';
part 'engine_bridge_remove_device_from_synth_audio_fx.dart';
part 'engine_bridge_add_device_to_synth_note_fx.dart';
part 'engine_bridge_remove_device_from_synth_note_fx.dart';
part 'engine_bridge_get_device_preset.dart';
part 'engine_bridge_apply_device_preset.dart';
part 'engine_bridge_set_drum_pad_parameter.dart';
part 'engine_bridge_set_device_parameter.dart';
part 'engine_bridge_set_device_string_parameter.dart';
part 'engine_bridge_set_master_gain.dart';
part 'engine_bridge_invoke_raw.dart';
part 'engine_bridge_set_playhead_beats.dart';
part 'engine_bridge_create_midi_clip.dart';
part 'engine_bridge_set_midi_clip_notes.dart';
part 'engine_bridge_add_midi_clip_take.dart';
part 'engine_bridge_set_midi_clip_take_region_take.dart';
part 'engine_bridge_set_midi_clip_take_at_beat.dart';
part 'engine_bridge_split_midi_clip_take_region_at_beat.dart';
part 'engine_bridge_move_midi_clip_take_marker.dart';
part 'engine_bridge_set_midi_clip_take_marker_mode.dart';
part 'engine_bridge_delete_midi_clip_take_marker.dart';
part 'engine_bridge_set_midi_clip_editor_scale.dart';
part 'engine_bridge_flatten_midi_comp.dart';
part 'engine_bridge_reopen_midi_comp.dart';
part 'engine_bridge_create_automation_clip.dart';
part 'engine_bridge_assign_automation_target.dart';
part 'engine_bridge_unlink_automation_target.dart';
part 'engine_bridge_set_automation_points.dart';
part 'engine_bridge_create_sample_clip.dart';
part 'engine_bridge_move_clip.dart';
part 'engine_bridge_set_clip_length.dart';
part 'engine_bridge_set_clip_loop_content.dart';
part 'engine_bridge_set_sample_clip_properties.dart';
part 'engine_bridge_set_sample_clip_warp.dart';
part 'engine_bridge_set_sample_clip_slices.dart';
part 'engine_bridge_set_sample_clip_take_region_take.dart';
part 'engine_bridge_set_sample_clip_take_at_beat.dart';
part 'engine_bridge_split_sample_clip_take_region_at_beat.dart';
part 'engine_bridge_move_sample_clip_take_marker.dart';
part 'engine_bridge_delete_sample_clip_take_marker.dart';
part 'engine_bridge_export_sample_clip_slices.dart';
part 'engine_bridge_delete_track.dart';
part 'engine_bridge_delete_clip.dart';
part 'engine_bridge_duplicate_clip.dart';
part 'engine_bridge_enter_play_mode.dart';
part 'engine_bridge_set_record_armed.dart';
part 'engine_bridge_note_on.dart';
part 'engine_bridge_note_off.dart';
part 'engine_bridge_all_notes_off.dart';
part 'engine_bridge_set_pitch_bend.dart';
part 'engine_bridge_set_modulation.dart';
part 'engine_bridge_clear_capture.dart';
part 'engine_bridge_commit_capture.dart';
part 'engine_bridge_begin_midi_recording_session.dart';
part 'engine_bridge_finish_midi_recording_session.dart';
part 'engine_bridge_cancel_midi_recording_session.dart';
part 'engine_bridge_create_lfo.dart';
part 'engine_bridge_remove_lfo.dart';
part 'engine_bridge_update_lfo_param.dart';
part 'engine_bridge_batch_update_lfo_params.dart';
part 'engine_bridge_assign_modulation.dart';
part 'engine_bridge_remove_modulation.dart';
part 'engine_bridge_apply_subtractive_synth_preset.dart';
part 'engine_bridge_set_metronome.dart';
part 'engine_bridge_invoke_ok.dart';
part 'engine_bridge_export_mix.dart';
part 'engine_bridge_preview_sample.dart';
part 'engine_bridge_preview_sample_region.dart';
part 'engine_bridge_preview_midi.dart';
part 'engine_bridge_preview_preset.dart';
part 'engine_bridge_stop_preview.dart';
part 'engine_bridge_get_param_descriptors.dart';
part 'engine_bridge_import_sample.dart';
part 'engine_bridge_begin_audio_recording_session.dart';
part 'engine_bridge_start_track_audio_recording.dart';
part 'engine_bridge_ensure_record_audio_permission.dart';
part 'engine_bridge_retarget_track_audio_recording.dart';
part 'engine_bridge_stop_track_audio_recording.dart';
part 'engine_bridge_cancel_track_audio_recording.dart';
part 'engine_bridge_get_track_audio_recording_level.dart';
part 'engine_bridge_finish_audio_recording_session.dart';
part 'engine_bridge_cancel_audio_recording_session.dart';
part 'engine_bridge_register_demo_sample.dart';
part 'engine_bridge_select_wavetable.dart';
part 'engine_bridge_save_project.dart';
part 'engine_bridge_load_project.dart';
part 'engine_bridge_get_recent_projects.dart';
part 'engine_bridge_load_recent_project.dart';
part 'engine_bridge_load_example_project.dart';
part 'engine_bridge_project_workspace.dart';
part 'engine_bridge_invoke_for_snapshot.dart';
part 'engine_bridge_snapshot_from_result.dart';

/// Flutter ↔ native engine bridge (MethodChannel + EventChannels).
class EngineBridge {
  EngineBridge({MethodChannel? channel, EventChannel? metersChannel})
      : _channel = channel ?? const MethodChannel('com.audioapp.daw/engine'),
        _metersChannel =
            metersChannel ?? const EventChannel('com.audioapp.daw/meters');

  final MethodChannel _channel;
  final EventChannel _metersChannel;
  final StreamController<LiveMidiNoteEvent> _noteEvents =
      StreamController<LiveMidiNoteEvent>.broadcast();

  Stream<LiveMidiNoteEvent> get noteEvents => _noteEvents.stream;

  /// Stream of live meter readings pushed from native engine (~60Hz when subscribed).
  /// Each event is a [LiveMetersBatch] containing subscribed device meters only.
  Stream<LiveMetersBatch> get meterStream =>
      _metersChannel.receiveBroadcastStream().map(
            (event) => LiveMetersBatch.fromMap(event as Map<dynamic, dynamic>),
          );

  /// Tells the engine which device IDs should publish live meter / analyzer data.
  /// Pass an empty list when the device strip is hidden or nothing is in view.
  /// Invoke and return raw result map (used for delta-aware calls).
  // ─── LFO & Modulation ─────────────────────────────────

  /// Batch-update multiple LFO parameters in a single bridge call.
  /// Each entry: { 'param': String, 'value': double }.
  /// Renders [lengthBeats] and saves via system dialog. Null if cancelled.
  /// Opens SAF picker for a WAV/audio file and imports into the sample library.
  /// Select a wavetable for a wavetable synth device.
  /// Opens the system save dialog for a `.audioapp.zip` archive.
  /// Returns the saved document URI, or null if the user cancelled.
  /// Opens the system open dialog for a `.audioapp.zip` archive.
  /// Returns null if the user cancelled.
  /// Loads a bundled example project from its raw `project.json` contents.
  /// Unlike [loadRecentProject], this never touches the OS document picker
  /// or the native "recent projects" store.
}
