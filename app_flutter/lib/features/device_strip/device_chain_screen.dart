import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/param_descriptor.dart';
import '../../bridge/project_snapshot.dart';
import '../content_library/library_browse_mode.dart';
import '../content_library/library_category.dart';
import '../content_library/library_device_family.dart';
import '../content_library/library_filter.dart';
import '../content_library/library_catalog.dart';
import '../content_library/library_fly_in_panel.dart';
import 'device_chain_layout.dart';
import 'device_chain_minimap.dart';
import 'device_chain_row.dart';
import 'device_strip_slot.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';

part 'device_chain_screen_device_chain_screen_state.dart';

/// Fullscreen horizontally scrollable device chain for the selected track.
class DeviceChainScreen extends StatefulWidget {
  const DeviceChainScreen({
    super.key,
    required this.snapshot,
    required this.track,
    required this.samples,
    required this.playing,
    required this.onSamplerParameterChanged,
    this.onDeviceStringParameterChanged,
    required this.onOpenSamplerEditor,
    required this.onFrequencyChanged,
    required this.onAddDevice,
    required this.onPreviewAudio,
    required this.onAssignSamplerSample,
    required this.onImportAudio,
    this.onSamplerTabChanged,
    this.samplerTabFor,
    this.onSynthTabChanged,
    this.synthTabFor,
    this.onBypassToggle,
    this.onDeleteDevice,
    this.onModulationBridgeCall,
    this.automationLinkClipId,
    this.onAutomationParamSelected,
    this.onAutomateParameter,
    this.onGetParamDescriptors,
    this.onMeterSubscriptionsChanged,
    this.onPresetTap,
    this.onWavetableTap,
  });

  final ProjectSnapshot snapshot;
  final TrackSnapshot track;
  final List<SampleLibraryEntrySnapshot> samples;
  final bool playing;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(String deviceId, String parameterId, String value)?
      onDeviceStringParameterChanged;
  final void Function(TrackSnapshot track, DeviceSnapshot device)
      onOpenSamplerEditor;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;
  final Future<ProjectSnapshot> Function(String deviceType, int insertIndex)
      onAddDevice;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final void Function(String deviceId, String sampleId) onAssignSamplerSample;
  final Future<void> Function() onImportAudio;
  final void Function(String deviceId, SamplerDeviceTab tab)?
      onSamplerTabChanged;
  final SamplerDeviceTab Function(String deviceId)? samplerTabFor;
  final void Function(String deviceId, SubtractiveDeviceTab tab)?
      onSynthTabChanged;
  final SubtractiveDeviceTab Function(String deviceId)? synthTabFor;
  final void Function(String deviceId, bool bypassed)? onBypassToggle;
  final Future<ProjectSnapshot?> Function(DeviceSnapshot device)?
      onDeleteDevice;
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
  final void Function(LibraryPresetItem item)? onPresetTap;
  final void Function(LibraryWavetableItem item)? onWavetableTap;

  @override
  State<DeviceChainScreen> createState() => _DeviceChainScreenState();
}
