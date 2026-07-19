part of 'daw_shell.dart';

extension DawShellStateOpendrumpadlibraryOperation on _DawShellState {
  void _openDrumPadLibrary(DrumMachineDeviceSnapshot device, int note) {
    setState(() {
      _libraryOpen = true;
      _libraryBrowseMode = LibraryBrowseMode.resources;
      _libraryCategory = LibraryCategory.audioClips;
      _libraryLockedFamily = null;
      _libraryInsertTrackId = null;
      _libraryInsertIndex = null;
      _librarySamplerDeviceId = null;
      _libraryDrumMachineId = device.id;
      _libraryDrumNote = note;
      _libraryPresetDeviceId = null;
      _libraryPresetDeviceType = null;
      _libraryWavetableDeviceId = null;
    });
  }
}
