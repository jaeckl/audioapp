import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'library_catalog.dart';
import 'library_category.dart';
import 'library_category_menu.dart';
import 'library_content_pane.dart';
import 'library_header.dart';
import 'library_manifest.dart';
import 'library_preset_preview_bar.dart';
import 'library_theme.dart';
import 'user_device_preset_store.dart';

part 'library_fly_in_panel_library_fly_in_panel_state.dart';

part 'library_fly_in_panel_library_fly_in_panel_state_start_preview_animation.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_stop_preview_animation.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_load_manifest.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_close.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_open_category.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_on_preset_preview_tap.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_compute_preview_length_beats.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_on_item_selected.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_on_insert.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_save_preset.dart';
part 'library_fly_in_panel_library_fly_in_panel_state_manage_user_preset.dart';
/// Slide-in content library: half width in landscape, full width in portrait.
class LibraryFlyInPanel extends StatefulWidget {
  const LibraryFlyInPanel({
    super.key,
    required this.snapshot,
    required this.onClose,
    required this.onPreviewAudio,
    required this.onInsertAudio,
    required this.onImportAudio,
    this.initialCategory = LibraryCategory.audioClips,
    this.onMidiClipTap,
    this.onMidiPreviewTap,
    this.onAutomationTap,
    this.onAutomationPreviewTap,
    this.onPresetTap,
    this.onPresetPreviewTap,
    this.onWavetableTap,
    this.onStopPreview,
    this.percussionOnly = false,
    this.presetDeviceId,
    this.presetDeviceType,
    this.onCaptureDevicePreset,
  });

  final ProjectSnapshot snapshot;
  final VoidCallback onClose;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final VoidCallback onImportAudio;
  final LibraryCategory initialCategory;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryMidiItem item)? onMidiPreviewTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryAutomationItem item)? onAutomationPreviewTap;
  final void Function(LibraryPresetItem item)? onPresetTap;
  final void Function(LibraryPresetItem item, {double startBeat, bool loop})?
      onPresetPreviewTap;
  final void Function(LibraryWavetableItem item)? onWavetableTap;

  /// Optional: invoked when the panel wants to halt any active engine preview
  /// (e.g. when the user toggles auto-play/loop off mid-preview).
  final VoidCallback? onStopPreview;
  final bool percussionOnly;
  final String? presetDeviceId, presetDeviceType;
  final Future<String> Function()? onCaptureDevicePreset;

  @override
  State<LibraryFlyInPanel> createState() => LibraryFlyInPanelState();
}
