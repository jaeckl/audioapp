part of 'daw_shell.dart';

extension DawShellStateOpendevicelibraryOperation on _DawShellState {
Future<void> _openDeviceLibrary(
      DeviceSnapshot device, LibraryFilter filter) async {
    setState(() {
      _libraryOpen = true;
      _libraryCategory = filter.defaultCategory;
      _libraryPresetDeviceId = device.id;
      _libraryPresetDeviceType = device.type;
      _librarySamplerDeviceId =
          filter.defaultCategory == LibraryCategory.audioClips
              ? device.id
              : null;
      _libraryWavetableDeviceId =
          filter.defaultCategory == LibraryCategory.wavetables
              ? device.id
              : null;
    });
  }
}
