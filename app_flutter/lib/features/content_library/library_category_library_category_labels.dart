part of 'library_category.dart';

extension LibraryCategoryLabels on LibraryCategory {
  String get title => switch (this) {
        LibraryCategory.audioClips => 'Audio',
        LibraryCategory.midiClips => 'MIDI',
        LibraryCategory.automationClips => 'Automation',
        LibraryCategory.curves => 'Curves',
        LibraryCategory.devicePresets => 'Presets',
        LibraryCategory.wavetables => 'Wavetables',
      };

  String get subtitle => switch (this) {
        LibraryCategory.audioClips => 'Samples & audio clips',
        LibraryCategory.midiClips => 'MIDI patterns',
        LibraryCategory.automationClips => 'Automation lanes',
        LibraryCategory.curves => 'Automation & modulation shapes',
        LibraryCategory.devicePresets => 'Device chains',
        LibraryCategory.wavetables => 'Bundled wavetables',
      };
}
