part of 'daw_shell.dart';

extension DawShellStateOpenlibraryOperation on _DawShellState {
Future<void> _openLibrary(
      {LibraryCategory category = LibraryCategory.audioClips}) async {
    setState(() {
      _libraryOpen = true;
      _libraryCategory = category;
      _librarySamplerDeviceId = null;
    });
  }
}
