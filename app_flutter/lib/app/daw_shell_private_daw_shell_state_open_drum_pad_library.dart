part of 'daw_shell.dart';

extension DawShellStateOpendrumpadlibraryOperation on _DawShellState {
void _openDrumPadLibrary(DrumMachineDeviceSnapshot device, int note) {
    setState(() {
      _libraryOpen = true;
      _libraryCategory = LibraryCategory.audioClips;
      _librarySamplerDeviceId = null;
      _libraryDrumMachineId = device.id;
      _libraryDrumNote = note;
    });
  }
}
