import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/live_meters_dto.dart';
import '../bridge/live_meters_store.dart';
import '../features/arrangement/arrangement_timeline_metrics.dart';
import 'daw_shell_nav.dart';
import 'daw_transport_controller.dart';
import '../bridge/engine_bridge.dart';
import '../bridge/project_snapshot.dart';
import '../bridge/transport_state.dart';
import '../bridge/snapshot_store.dart';
import '../features/automation/automation_editor_screen.dart';
import '../features/arrangement/arrangement_view.dart';
import '../features/arrangement/snap_grid_resolution.dart';
import '../features/clip_drag/sample_clip_drag_data.dart';
import '../features/editor/timeline_marker_layer.dart';
import '../features/content_library/library_browse_mode.dart';
import '../features/content_library/library_catalog.dart';
import '../features/content_library/library_category.dart';
import '../features/content_library/library_device_family.dart';
import '../features/content_library/library_filter.dart';
import '../features/content_library/library_fly_in_panel.dart';
import '../features/device_strip/device_strip.dart';
import '../features/device_strip/device_strip_device_kind.dart';
import '../features/device_strip/device_strip_theme.dart';
import '../features/device_strip/device_preset_store.dart';
import '../features/device_strip/effective_parameter_monitor.dart';
import '../features/device_strip/nesting_error_messages.dart';
import '../features/device_strip/subtractive_synth_editor_screen.dart';
import '../features/device_strip/subtractive_synth_presets.dart';
import '../features/mixer/mixer_view.dart';
import '../features/play/live_instrument_panel.dart';
import '../features/piano_roll/piano_roll_screen.dart';
import '../features/piano_roll/midi_lane_layout.dart';
import '../features/sample_library/sample_library_screen.dart';
import '../features/sample_editor/sample_editor_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/app_settings_store.dart';
import '../features/settings/audio_engine_settings.dart';
import '../features/settings/project_hub_screen.dart';
import '../features/welcome/example_projects.dart';
import '../features/welcome/welcome_hub.dart';
import '../features/welcome/project_workspace_browser.dart';
import '../features/transport/transport_bar.dart';
import 'automation_recording_merge.dart';
import 'automation_recording_session.dart';
import 'midi_recording_merge.dart';
import 'recording_session_decision.dart';
import 'record_write_mode.dart';

part 'daw_shell_private_shell_tab.dart';
part 'daw_shell_private_midi_recording_preview_note.dart';
part 'daw_shell_private_pending_midi_recording_take.dart';
part 'daw_shell_private_daw_shell_state.dart';
part 'daw_shell_private_daw_shell_state_on_store_changed.dart';
part 'daw_shell_private_daw_shell_state_on_meters_batch.dart';
part 'daw_shell_private_daw_shell_state_update_meter_subscriptions.dart';
part 'daw_shell_private_daw_shell_state_begin_clip_editor_session.dart';
part 'daw_shell_private_daw_shell_state_end_clip_editor_session.dart';
part 'daw_shell_private_daw_shell_state_bootstrap.dart';
part 'daw_shell_private_daw_shell_state_refresh_recent_projects.dart';
part 'daw_shell_private_daw_shell_state_present_welcome_hub.dart';
part 'daw_shell_private_daw_shell_state_activate_project.dart';
part 'daw_shell_private_daw_shell_state_register_demo_samples.dart';
part 'daw_shell_private_daw_shell_state_create_new_project.dart';
part 'daw_shell_private_daw_shell_state_request_new_project.dart';
part 'daw_shell_private_daw_shell_state_continue_project.dart';
part 'daw_shell_private_daw_shell_state_load_recent_project.dart';
part 'daw_shell_private_daw_shell_state_load_example_project.dart';
part 'daw_shell_private_daw_shell_state_refresh_snapshot.dart';
part 'daw_shell_private_daw_shell_state_apply_delta_mutation.dart';
part 'daw_shell_private_daw_shell_state_add_track.dart';
part 'daw_shell_private_daw_shell_state_add_group_track.dart';
part 'daw_shell_private_daw_shell_state_set_track_group.dart';
part 'daw_shell_private_daw_shell_state_move_track.dart';
part 'daw_shell_private_daw_shell_state_set_track_muted.dart';
part 'daw_shell_private_daw_shell_state_set_track_soloed.dart';
part 'daw_shell_private_daw_shell_state_toggle_track_freeze.dart';
part 'daw_shell_private_daw_shell_state_track_frozen.dart';
part 'daw_shell_private_daw_shell_state_show_frozen_track_snack.dart';
part 'daw_shell_private_daw_shell_state_select_track.dart';
part 'daw_shell_private_daw_shell_state_sync_arm_with_selection.dart';
part 'daw_shell_private_daw_shell_state_sync_live_input_for_tab.dart';
part 'daw_shell_private_daw_shell_state_set_record_armed.dart';
part 'daw_shell_private_daw_shell_state_set_record_write_mode.dart';
part 'daw_shell_private_daw_shell_state_set_track_record_armed.dart';
part 'daw_shell_private_daw_shell_state_add_midi_clip.dart';
part 'daw_shell_private_daw_shell_state_track_by_id.dart';
part 'daw_shell_private_daw_shell_state_add_automation_clip.dart';
part 'daw_shell_private_daw_shell_state_toggle_automation_link.dart';
part 'daw_shell_private_daw_shell_state_assign_automation_param.dart';
part 'daw_shell_private_daw_shell_state_automation_value_for_device.dart';
part 'daw_shell_private_daw_shell_state_automate_parameter.dart';
part 'daw_shell_private_daw_shell_state_open_automation_curve_editor.dart';
part 'daw_shell_private_daw_shell_state_add_audio_clip.dart';
part 'daw_shell_private_daw_shell_state_optimistic_param_update.dart';
part 'daw_shell_private_daw_shell_state_track_owning_device.dart';
part 'daw_shell_private_daw_shell_state_capture_automation_for_device_param.dart';
part 'daw_shell_private_daw_shell_state_set_sampler_parameter.dart';
part 'daw_shell_private_daw_shell_state_queue_wt_position_parameter.dart';
part 'daw_shell_private_daw_shell_state_flush_queued_wt_position_parameter.dart';
part 'daw_shell_private_daw_shell_state_set_device_bypass.dart';
part 'daw_shell_private_daw_shell_state_modulation_bridge_call.dart';
part 'daw_shell_private_daw_shell_state_open_device_library.dart';
part 'daw_shell_private_daw_shell_state_open_drum_pad_library.dart';
part 'daw_shell_private_daw_shell_state_close_library.dart';
part 'daw_shell_private_daw_shell_state_open_library.dart';
part 'daw_shell_private_daw_shell_state_open_insert_library.dart';
part 'daw_shell_private_daw_shell_state_on_library_insert_device_type.dart';
part 'daw_shell_private_daw_shell_state_on_library_insert_audio.dart';
part 'daw_shell_private_daw_shell_state_on_library_midi_tap.dart';
part 'daw_shell_private_daw_shell_state_on_library_midi_preview_tap.dart';
part 'daw_shell_private_daw_shell_state_on_library_automation_preview_tap.dart';
part 'daw_shell_private_daw_shell_state_on_library_automation_tap.dart';
part 'daw_shell_private_daw_shell_state_on_library_preset_tap.dart';
part 'daw_shell_private_daw_shell_state_on_library_preset_preview_tap.dart';
part 'daw_shell_private_daw_shell_state_assign_sampler_sample.dart';
part 'daw_shell_private_daw_shell_state_create_sampler_from_dropped_sample.dart';
part 'daw_shell_private_daw_shell_state_assign_dropped_sample_to_device.dart';
part 'daw_shell_private_daw_shell_state_set_device_string_parameter.dart';
part 'daw_shell_private_daw_shell_state_on_library_wavetable_tap.dart';
part 'daw_shell_private_daw_shell_state_open_sampler_editor.dart';
part 'daw_shell_private_daw_shell_state_set_frequency.dart';
part 'daw_shell_private_daw_shell_state_add_device_to_track.dart';
part 'daw_shell_private_daw_shell_state_set_track_gain.dart';
part 'daw_shell_private_daw_shell_state_set_track_pan.dart';
part 'daw_shell_private_daw_shell_state_set_master_gain.dart';
part 'daw_shell_private_daw_shell_state_save_project.dart';
part 'daw_shell_private_daw_shell_state_load_project.dart';
part 'daw_shell_private_daw_shell_state_import_sample.dart';
part 'daw_shell_private_daw_shell_state_insert_sample.dart';
part 'daw_shell_private_daw_shell_state_preview_sample.dart';
part 'daw_shell_private_daw_shell_state_preview_sampler_note.dart';
part 'daw_shell_private_daw_shell_state_open_piano_roll.dart';
part 'daw_shell_private_daw_shell_state_open_sample_editor.dart';
part 'daw_shell_private_daw_shell_state_set_bpm.dart';
part 'daw_shell_private_daw_shell_state_set_loop_enabled.dart';
part 'daw_shell_private_daw_shell_state_set_loop_region.dart';
part 'daw_shell_private_daw_shell_state_duplicate_clip.dart';
part 'daw_shell_private_daw_shell_state_confirm_delete_track.dart';
part 'daw_shell_private_daw_shell_state_confirm_remove_device.dart';
part 'daw_shell_private_daw_shell_state_confirm_delete_clip.dart';
part 'daw_shell_private_daw_shell_state_export_mix.dart';
part 'daw_shell_private_daw_shell_state_move_clip.dart';
part 'daw_shell_private_daw_shell_state_resize_clip.dart';
part 'daw_shell_private_daw_shell_state_set_clip_loop_content.dart';
part 'daw_shell_private_daw_shell_state_set_playhead_beats.dart';
part 'daw_shell_private_daw_shell_state_jump_to_start.dart';
part 'daw_shell_private_daw_shell_state_start_play.dart';
part 'daw_shell_private_daw_shell_state_begin_recording_after_count_in.dart';
part 'daw_shell_private_daw_shell_state_recording_target_clip_id.dart';
part 'daw_shell_private_daw_shell_state_midi_recording_target_for_mode.dart';
part 'daw_shell_private_daw_shell_state_begin_midi_recording_pass.dart';
part 'daw_shell_private_daw_shell_state_wait_for_count_in_to_finish.dart';
part 'daw_shell_private_daw_shell_state_create_midi_recording_preview_clip.dart';
part 'daw_shell_private_daw_shell_state_update_live_recording_previews.dart';
part 'daw_shell_private_daw_shell_state_update_midi_recording_preview.dart';
part 'daw_shell_private_daw_shell_state_current_midi_recording_preview_notes.dart';
part 'daw_shell_private_daw_shell_state_update_automation_recording_previews.dart';
part 'daw_shell_private_daw_shell_state_ensure_automation_recording_clip.dart';
part 'daw_shell_private_daw_shell_state_automation_recording_target_for_mode.dart';
part 'daw_shell_private_daw_shell_state_start_audio_recording_snapshot_refresh.dart';
part 'daw_shell_private_daw_shell_state_roll_loop_recording_if_needed.dart';
part 'daw_shell_private_daw_shell_state_record_automation_point.dart';
part 'daw_shell_private_daw_shell_state_on_live_midi_note.dart';
part 'daw_shell_private_daw_shell_state_stash_current_midi_recording_take.dart';
part 'daw_shell_private_daw_shell_state_finish_midi_recording_session.dart';
part 'daw_shell_private_daw_shell_state_finish_automation_recording_segment.dart';
part 'daw_shell_private_daw_shell_state_automation_preview_length.dart';
part 'daw_shell_private_daw_shell_state_automation_preview_points.dart';
part 'daw_shell_private_daw_shell_state_set_metronome.dart';
part 'daw_shell_private_daw_shell_state_stop_play.dart';
part 'daw_shell_private_daw_shell_state_cancel_audio_recording.dart';
part 'daw_shell_private_daw_shell_state_set_follow_playhead_enabled.dart';
part 'daw_shell_private_daw_shell_state_on_follow_suspended.dart';
part 'daw_shell_private_daw_shell_state_on_follow_resumed.dart';
part 'daw_shell_private_daw_shell_state_on_tab_selected.dart';
part 'daw_shell_private_daw_shell_state_build_arrangement_column.dart';
part 'daw_shell_private_daw_shell_state_build_tab_body.dart';
part 'daw_shell_private_daw_shell_state_build_main_column.dart';

const _demoSamples = <(String, String, String)>[
  ('demo_form_basic_e', 'Basic E', 'form_basic_e.wav'),
  ('demo_form_evolving_sines', 'Evolving Sines', 'form_evolving_sines.wav'),
  ('demo_form_vowel_sustain', 'Vowel Sustain', 'form_vowel_sustain.wav'),
  ('demo_form_lost_choir', 'Lost Choir', 'form_lost_choir.wav'),
  ('demo_form_metal_hollow', 'Metal Hollow', 'form_metal_hollow.wav'),
  ('demo_form_vox_riders', 'Vox Riders', 'form_vox_riders.wav'),
  ('demo_form_liquid_air', 'Liquid Air', 'form_liquid_air.wav'),
];

class DawShell extends StatefulWidget {
  const DawShell({
    super.key,
    required this.bridge,
    this.showWelcomeOnLaunch = false,
    this.initialAudioEngineProfile = AudioEngineProfile.balanced,
    this.initialCustomAudioSettings = const AudioEngineCustomSettings(),
  });

  final EngineBridge bridge;
  final bool showWelcomeOnLaunch;
  final AudioEngineProfile initialAudioEngineProfile;
  final AudioEngineCustomSettings initialCustomAudioSettings;

  @override
  State<DawShell> createState() => _DawShellState();
}
