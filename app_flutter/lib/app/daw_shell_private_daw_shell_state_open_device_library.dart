part of 'daw_shell.dart';

extension DawShellStateOpendevicelibraryOperation on _DawShellState {
  Future<void> _openDeviceLibrary(
      DeviceSnapshot device, LibraryFilter filter) async {
    final resourceBrowse = filter.defaultCategory == LibraryCategory.audioClips ||
        filter.defaultCategory == LibraryCategory.wavetables;
    setState(() {
      _libraryOpen = true;
      _libraryBrowseMode = resourceBrowse
          ? LibraryBrowseMode.resources
          : LibraryBrowseMode.devices;
      _libraryCategory = filter.defaultCategory == LibraryCategory.devicePresets
          ? LibraryCategory.audioClips
          : filter.defaultCategory;
      _libraryDeviceFamily = libraryDeviceFamilyForType(device.type);
      _libraryLockedFamily = null;
      _libraryInsertTrackId = null;
      _libraryInsertIndex = null;
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
