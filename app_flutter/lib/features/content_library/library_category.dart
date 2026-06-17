/// Content library categories.
enum LibraryCategory {
  audioClips,
  midiClips,
  automationClips,
  devicePresets,
}

extension LibraryCategoryLabels on LibraryCategory {
  String get title => switch (this) {
        LibraryCategory.audioClips => 'Audio',
        LibraryCategory.midiClips => 'MIDI',
        LibraryCategory.automationClips => 'Automation',
        LibraryCategory.devicePresets => 'Presets',
      };

  String get subtitle => switch (this) {
        LibraryCategory.audioClips => 'Samples & audio clips',
        LibraryCategory.midiClips => 'MIDI patterns',
        LibraryCategory.automationClips => 'Automation lanes',
        LibraryCategory.devicePresets => 'Device chains',
      };
}
