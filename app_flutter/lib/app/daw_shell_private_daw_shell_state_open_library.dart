part of 'daw_shell.dart';

extension DawShellStateOpenlibraryOperation on _DawShellState {
  Future<void> _openLibrary(
      {LibraryCategory category = LibraryCategory.audioClips}) async {
    setState(() {
      _libraryOpen = true;
      _libraryBrowseMode = LibraryBrowseMode.resources;
      _libraryCategory = category == LibraryCategory.devicePresets
          ? LibraryCategory.audioClips
          : category;
      _libraryLockedFamily = null;
      _libraryInsertTrackId = null;
      _libraryInsertIndex = null;
      _librarySamplerDeviceId = null;
      _libraryPresetDeviceId = null;
      _libraryPresetDeviceType = null;
      _libraryWavetableDeviceId = null;
    });
  }
}
