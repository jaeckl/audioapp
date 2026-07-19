part 'library_category_library_category_labels.dart';

/// Content library categories (resource browse mode).
enum LibraryCategory {
  audioClips,
  midiClips,
  automationClips,
  curves,
  devicePresets,
  wavetables,
}

/// Default Library tab rail — resources only (no device presets).
const kLibraryResourceRail = <LibraryCategory>[
  LibraryCategory.audioClips,
  LibraryCategory.midiClips,
  LibraryCategory.automationClips,
  LibraryCategory.curves,
  LibraryCategory.wavetables,
];
