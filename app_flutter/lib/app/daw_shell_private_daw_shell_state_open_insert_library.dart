part of 'daw_shell.dart';

extension DawShellStateOpeninsertlibraryOperation on _DawShellState {
  /// Opens the library in devices mode and resolves when the user adds a
  /// device type (or cancels / closes). Used by device-strip `+` and virtual
  /// FX insert slots.
  Future<String?> _pickDeviceFromLibrary({
    LibraryDeviceFamily? lockedFamily,
  }) async {
    _libraryDevicePickCompleter?.complete(null);
    final completer = Completer<String?>();
    _libraryDevicePickCompleter = completer;
    setState(() {
      _libraryOpen = true;
      _libraryBrowseMode = LibraryBrowseMode.devices;
      _libraryDeviceFamily = lockedFamily ?? LibraryDeviceFamily.instrument;
      _libraryLockedFamily = lockedFamily;
      _libraryInsertTrackId = null;
      _libraryInsertIndex = null;
      _libraryPresetDeviceId = null;
      _libraryPresetDeviceType = null;
      _librarySamplerDeviceId = null;
      _libraryWavetableDeviceId = null;
      _libraryDrumMachineId = null;
    });
    return completer.future;
  }
}
