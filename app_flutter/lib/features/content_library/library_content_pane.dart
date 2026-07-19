import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_preset_filter_list.dart';
import 'curve_library_store.dart';
import 'library_catalog.dart';
import 'library_category.dart';
import 'library_manifest.dart';
import 'library_preview_widget.dart';
import 'library_tags.dart';
import 'library_theme.dart';
import 'user_device_preset_store.dart';
import '../welcome/welcome_theme.dart';

part 'library_content_pane_library_content_pane_state.dart';
part 'library_content_pane_resource_path_bar.dart';
part 'library_content_pane_resource_nav_tile.dart';
part 'library_content_pane_resource_pages.dart';
part 'library_content_pane_filtered_empty_state.dart';
part 'library_content_pane_empty_category_state.dart';
part 'library_content_pane_library_item_tile.dart';
part 'library_content_pane_leading_visual.dart';

class LibraryContentPane extends StatefulWidget {
  const LibraryContentPane({
    super.key,
    required this.category,
    required this.snapshot,
    required this.onPreviewAudio,
    required this.onInsertAudio,
    required this.onImportAudio,
    this.onItemSelected,
    this.onMidiClipTap,
    this.onMidiPreviewTap,
    this.onAutomationTap,
    this.onAutomationPreviewTap,
    this.onPresetTap,
    this.onPresetPreviewTap,
    this.onWavetableTap,
    this.autoPlayOnSelect = true,
    this.presetManifest,
    this.percussionOnly = false,
    this.presetDeviceType,
    this.onUserPresetLongPress,
  });

  final LibraryCategory category;
  final ProjectSnapshot snapshot;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final VoidCallback onImportAudio;
  final ValueChanged<String?>? onItemSelected;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryMidiItem item)? onMidiPreviewTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryAutomationItem item)? onAutomationPreviewTap;
  final void Function(LibraryPresetItem item)? onPresetTap;
  final void Function(LibraryPresetItem item, {double startBeat, bool loop})?
      onPresetPreviewTap;
  final void Function(LibraryWavetableItem item)? onWavetableTap;

  /// When true (default), selecting a preset auto-starts preview. When false,
  /// only the explicit play button on the tile starts preview.
  final bool autoPlayOnSelect;

  /// Optional manifest override (tests). When null, loads from assets.
  final LibraryManifest? presetManifest;
  final bool percussionOnly;
  final String? presetDeviceType;
  final ValueChanged<LibraryPresetItem>? onUserPresetLongPress;

  @override
  State<LibraryContentPane> createState() => _LibraryContentPaneState();
}
