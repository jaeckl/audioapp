import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/param_descriptor.dart';
import '../../bridge/device_capabilities.dart';
import '../../bridge/live_meters_dto.dart';
import '../../bridge/project_snapshot.dart';
import '../content_library/library_filter.dart';
import '../content_library/library_device_family.dart';
import '../clip_drag/sample_clip_drag_data.dart';
import 'device_chain_separator.dart';
import 'device_drag_data.dart';
import 'device_strip_device_kind.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';
import 'device_strip_theme.dart';
import 'device_picker_sheet.dart';
import 'device_chain_layout.dart';
import 'device_insert_slot.dart';
import 'meter_subscription.dart';
import 'live_automation_value.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';
import 'routing_device_panel.dart';
import 'audio_source_picker.dart';

part 'device_chain_row_private_device_chain_row_state.dart';
part 'device_chain_row_private_virtual_chain_bracket_painter.dart';
part 'device_chain_row_private_device_chain_row_state_sample_drop_target.dart';
part 'device_chain_row_private_device_chain_row_state_automation_aware_device.dart';
part 'device_chain_row_private_device_chain_row_state_virtual_device_chain.dart';
part 'device_chain_row_private_device_chain_row_state_virtual_split_branch.dart';
part 'device_chain_row_private_device_chain_row_state_virtual_multiband_band.dart';
part 'device_chain_row_private_device_chain_row_state_virtual_spectral_loud.dart';
part 'device_chain_row_private_device_chain_row_state_virtual_pad_chain.dart';
part 'device_chain_row_private_device_chain_row_state_virtual_audio_fx_chain.dart';
part 'device_chain_row_private_device_chain_row_state_virtual_note_fx_chain.dart';
part 'device_chain_row_private_device_chain_row_state_virtual_nested.dart';
part 'device_chain_row_private_device_chain_row_state_leading_insert.dart';

/// Horizontally scrollable Bitwig/Ableton-style device chain row.
class DeviceChainRow extends StatefulWidget {
  const DeviceChainRow({
    super.key,
    required this.track,
    this.routingSnapshot,
    required this.samples,
    required this.playing,
    required this.bpm,
    this.playheadBeat = 0,
    this.playheadBeatListenable,
    this.liveMetersListenable,
    required this.density,
    required this.onSamplerParameterChanged,
    this.onDeviceStringParameterChanged,
    required this.onOpenSamplerEditor,
    required this.onFrequencyChanged,
    required this.onInsertDevice,
    this.onSamplerTabChanged,
    this.onSynthTabChanged,
    this.onCollapse,
    this.samplerTabFor,
    this.synthTabFor,
    this.scrollController,
    this.onBypassToggle,
    this.onDeleteDevice,
    this.onOpenLibrary,
    this.onOpenDrumPadLibrary,
    this.onPickDeviceType,
    this.onPreviewSample,
    this.onPreviewSampler,
    this.lfos = const [],
    this.modEdges = const [],
    this.onModulationBridgeCall,
    this.automationLinkActive = false,
    this.automationLinkClipId,
    this.projectAutomationClips = const [],
    this.onAutomationParamSelected,
    this.onAutomateParameter,
    this.onGetParamDescriptors,
    this.drumSelectedNoteFor,
    this.drumBankStartFor,
    this.drumChainExpandedFor,
    this.onDrumPadSelected,
    this.onDrumBankChanged,
    this.onDrumChainToggle,
    this.onMeterSubscriptionsChanged,
    this.onExpandChanged,
    this.onCreateSamplerFromDroppedSample,
    this.onAssignDroppedSampleToDevice,
    this.onMoveDevice,
  });

  final TrackSnapshot track;
  final ProjectSnapshot? routingSnapshot;
  final List<SampleLibraryEntrySnapshot> samples;
  final bool playing;
  final int bpm;
  final double playheadBeat;
  final ValueListenable<double>? playheadBeatListenable;
  final ValueListenable<Map<String, DeviceMeterReading>>? liveMetersListenable;
  final DeviceStripSlotDensity density;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(String deviceId, String parameterId, String value)?
      onDeviceStringParameterChanged;
  final void Function(TrackSnapshot track, DeviceSnapshot device)
      onOpenSamplerEditor;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;
  final Future<ProjectSnapshot?> Function(int insertIndex) onInsertDevice;
  final void Function(String deviceId, SamplerDeviceTab tab)?
      onSamplerTabChanged;
  final void Function(String deviceId, SubtractiveDeviceTab tab)?
      onSynthTabChanged;
  final VoidCallback? onCollapse;
  final SamplerDeviceTab Function(String deviceId)? samplerTabFor;
  final SubtractiveDeviceTab Function(String deviceId)? synthTabFor;
  final ScrollController? scrollController;
  final void Function(String deviceId, bool bypassed)? onBypassToggle;
  final Future<ProjectSnapshot?> Function(DeviceSnapshot device)?
      onDeleteDevice;
  final void Function(DeviceSnapshot device, LibraryFilter filter)?
      onOpenLibrary;
  final void Function(DrumMachineDeviceSnapshot device, int note)?
      onOpenDrumPadLibrary;
  final Future<String?> Function({LibraryDeviceFamily? lockedFamily})?
      onPickDeviceType;
  final ValueChanged<SampleLibraryEntrySnapshot>? onPreviewSample;
  final ValueChanged<int>? onPreviewSampler;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final Future<ProjectSnapshot> Function(
      String method, Map<String, dynamic> args)? onModulationBridgeCall;
  final bool automationLinkActive;
  final String? automationLinkClipId;
  final List<AutomationClipSnapshot> projectAutomationClips;
  final Future<bool> Function(String deviceId, String paramId)?
      onAutomationParamSelected;
  final void Function(String deviceId, String paramId)? onAutomateParameter;

  /// Optional: fetch param descriptors for the generic fallback editor.
  final Future<List<DeviceParamDescriptor>> Function(String deviceType)?
      onGetParamDescriptors;
  final int Function(String deviceId)? drumSelectedNoteFor;
  final int Function(String deviceId)? drumBankStartFor;
  final bool Function(String deviceId)? drumChainExpandedFor;
  final void Function(String deviceId, int note)? onDrumPadSelected;
  final void Function(String deviceId, int start)? onDrumBankChanged;
  final ValueChanged<String>? onDrumChainToggle;
  final ValueChanged<List<String>>? onMeterSubscriptionsChanged;
  final ValueChanged<DeviceChainExpandState>? onExpandChanged;
  final Future<void> Function(SampleClipDragData sample, int insertIndex)?
      onCreateSamplerFromDroppedSample;
  final Future<void> Function(DeviceSnapshot device, SampleClipDragData sample)?
      onAssignDroppedSampleToDevice;
  final Future<void> Function(String deviceId, int toIndex)? onMoveDevice;

  @override
  State<DeviceChainRow> createState() => _DeviceChainRowState();
}
