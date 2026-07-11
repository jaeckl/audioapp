part of 'daw_shell.dart';

extension DawShellStateCloselibraryOperation on _DawShellState {
void _closeLibrary() {
    setState(() {
      _libraryOpen = false;
      _librarySamplerDeviceId = null;
      _libraryWavetableDeviceId = null;
      _libraryDrumMachineId = null;
      _libraryDrumNote = null;
      _libraryPresetDeviceId = null;
      _libraryPresetDeviceType = null;
    });
    // Stop any active preview (preset/midi/sampler) so closing the library
    // also halts the audio and the visual playhead ticker — not just the
    // panel UI.
    widget.bridge.stopPreview().catchError((Object _) {});
  }
}
