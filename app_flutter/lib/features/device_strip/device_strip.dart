import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/param_descriptor.dart';
import '../../bridge/live_meters_dto.dart';
import '../../bridge/project_snapshot.dart';
import '../content_library/library_catalog.dart';
import '../content_library/library_filter.dart';
import '../clip_drag/sample_clip_drag_data.dart';
import 'device_chain_row.dart';
import 'device_chain_screen.dart';
import 'device_picker_sheet.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';

part 'device_strip_device_strip_state.dart';
part 'device_strip_device_strip_header.dart';
part 'device_strip_freeze_strip_badge.dart';

class DeviceStrip extends StatefulWidget {
  const DeviceStrip({
    super.key,
    required this.snapshot,
    required this.track,
    required this.samples,
    required this.playing,
    this.playheadBeatListenable,
    this.playheadBeats = 0,
    this.liveMetersListenable,
    required this.onSamplerParameterChanged,
    this.onDeviceStringParameterChanged,
    required this.onAssignSamplerSample,
    required this.onOpenSamplerEditor,
    required this.onPreviewSample,
    this.onPreviewSampler,
    required this.onImportSamples,
    required this.onFrequencyChanged,
    required this.onAddDevice,
    required this.onBypassToggle,
    required this.onRemoveDevice,
    required this.onOpenDeviceLibrary,
    this.onOpenDrumPadLibrary,
    this.onModulationBridgeCall,
    this.automationLinkClipId,
    this.onAutomationParamSelected,
    this.onAutomateParameter,
    this.onGetParamDescriptors,
    this.onMeterSubscriptionsChanged,
    this.onCreateSamplerFromDroppedSample,
    this.onAssignDroppedSampleToDevice,
    this.onPresetTap,
    this.onWavetableTap,
  });

  final ProjectSnapshot snapshot;
  final TrackSnapshot? track;
  final List<SampleLibraryEntrySnapshot> samples;
  final bool playing;
  final ValueListenable<double>? playheadBeatListenable;
  final double playheadBeats;
  final ValueListenable<Map<String, DeviceMeterReading>>? liveMetersListenable;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(String deviceId, String parameterId, String value)?
      onDeviceStringParameterChanged;
  final void Function(String deviceId, String sampleId) onAssignSamplerSample;
  final void Function(TrackSnapshot track, DeviceSnapshot device)
      onOpenSamplerEditor;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewSample;
  final ValueChanged<int>? onPreviewSampler;
  final Future<List<SampleLibraryEntrySnapshot>> Function() onImportSamples;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;
  final Future<ProjectSnapshot> Function(
      String trackId, String deviceType, int insertIndex) onAddDevice;
  final void Function(String deviceId, bool bypassed) onBypassToggle;
  final Future<ProjectSnapshot?> Function(
      TrackSnapshot track, DeviceSnapshot device) onRemoveDevice;
  final void Function(DeviceSnapshot device, LibraryFilter filter)
      onOpenDeviceLibrary;
  final void Function(DrumMachineDeviceSnapshot device, int note)?
      onOpenDrumPadLibrary;
  final Future<ProjectSnapshot> Function(
      String method, Map<String, dynamic> args)? onModulationBridgeCall;
  final String? automationLinkClipId;
  final Future<bool> Function(String deviceId, String paramId)?
      onAutomationParamSelected;
  final void Function(String deviceId, String paramId)? onAutomateParameter;

  /// Optional: fetch param descriptors for the generic fallback editor.
  final Future<List<DeviceParamDescriptor>> Function(String deviceType)?
      onGetParamDescriptors;
  final ValueChanged<List<String>>? onMeterSubscriptionsChanged;
  final Future<void> Function(
    TrackSnapshot track,
    SampleClipDragData sample,
    int insertIndex,
  )? onCreateSamplerFromDroppedSample;
  final Future<void> Function(DeviceSnapshot device, SampleClipDragData sample)?
      onAssignDroppedSampleToDevice;
  final void Function(LibraryPresetItem item)? onPresetTap;
  final void Function(LibraryWavetableItem item)? onWavetableTap;

  @override
  State<DeviceStrip> createState() => _DeviceStripState();
}
