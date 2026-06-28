import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

class RoutingSourceOption {
  const RoutingSourceOption(
      {required this.id, required this.label, required this.isMidi,
      required this.trackId, required this.deviceIndex,
      this.disabled = false, this.disabledReason});
  final String id;
  final String label;
  final bool isMidi;
  final String trackId;
  final int deviceIndex;
  final bool disabled;
  final String? disabledReason;
}

List<RoutingSourceOption> buildRoutingSourceOptions(
  ProjectSnapshot snapshot,
  TrackSnapshot destinationTrack,
  RoutingDeviceSnapshot receiver,
) {
  final tracks = [
    for (final track in snapshot.tracks)
      track.id == destinationTrack.id ? destinationTrack : track,
  ];
  final raw = <RoutingSourceOption>[];
  for (final track in tracks) {
    raw.add(RoutingSourceOption(
      id: 'track-midi:${track.id}', label: '${track.name} · MIDI',
      isMidi: true, trackId: track.id, deviceIndex: -1,
    ));
    for (var index = 0; index < track.devices.length; index++) {
      final device = track.devices[index];
      if (device.type == 'midi_delay') {
        raw.add(RoutingSourceOption(
          id: device.id, label: '${track.name} · MIDI Delay', isMidi: true,
          trackId: track.id, deviceIndex: index,
        ));
      } else if (device.type != 'audio_receiver' &&
          device.type != 'midi_receiver') {
        raw.add(RoutingSourceOption(
          id: device.id,
          label: '${track.name} · ${DeviceStripTheme.labelForDeviceType(device.type)}',
          isMidi: false, trackId: track.id, deviceIndex: index,
        ));
      }
    }
  }

  final sourceById = {for (final source in raw) source.id: source};
  final adjacency = <String, Set<String>>{};
  for (final track in tracks) {
    if (track.parentGroupId.isNotEmpty) {
      adjacency
          .putIfAbsent(track.id, () => <String>{})
          .add(track.parentGroupId);
    }
  }
  for (final track in tracks) {
    for (final device in track.devices) {
      if (device is! RoutingDeviceSnapshot || device.id == receiver.id ||
          device.sourceId.isEmpty) {
        continue;
      }
      final source = sourceById[device.sourceId];
      if (source != null && source.trackId != track.id) {
        adjacency.putIfAbsent(source.trackId, () => <String>{}).add(track.id);
      }
    }
  }

  bool reaches(String from, String target, Set<String> seen) {
    if (from == target) return true;
    if (!seen.add(from)) {
      return false;
    }
    return adjacency[from]?.any((next) => reaches(next, target, seen)) ?? false;
  }

  final receiverIndex = destinationTrack.devices.indexWhere((d) => d.id == receiver.id);
  return raw.where((source) => source.isMidi == !receiver.isAudioRoute).map((source) {
    String? reason;
    if (source.trackId == destinationTrack.id && source.deviceIndex >= receiverIndex &&
        source.deviceIndex >= 0) {
      reason = 'must be before receiver';
    } else if (source.trackId != destinationTrack.id &&
        reaches(destinationTrack.id, source.trackId, <String>{})) {
      reason = 'would create cycle';
    }
    return RoutingSourceOption(
      id: source.id, label: source.label, isMidi: source.isMidi,
      trackId: source.trackId, deviceIndex: source.deviceIndex,
      disabled: reason != null, disabledReason: reason,
    );
  }).toList();
}

class RoutingDevicePanel extends StatelessWidget {
  const RoutingDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    required this.sources,
    required this.onSourceChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const double designWidth = 210;
  static const containerTabs = <DeviceTabSpec>[];

  final RoutingDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final List<RoutingSourceOption> sources;
  final ValueChanged<String> onSourceChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final accent = DeviceStripTheme.accentForDeviceType(device.type);
    final selectedId = sources.any((source) => source.id == device.sourceId)
        ? device.sourceId : '';
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF12121A),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.call_received,
                      color: accent,
                      size: 25,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      device.isAudioRoute ? 'RECEIVE AUDIO' : 'RECEIVE MIDI',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('SOURCE',
              style: TextStyle(color: Colors.white38, fontSize: 9)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            key: const ValueKey('route-source'),
            initialValue: selectedId,
            isExpanded: true,
            dropdownColor: const Color(0xFF1B1B25),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
            hint: const Text('Choose source',
                style: TextStyle(color: Colors.white38)),
            items: [
              const DropdownMenuItem(value: '', child: Text('Disconnect')),
              ...sources.map((source) => DropdownMenuItem(
                      value: source.id,
                      enabled: !source.disabled,
                      child: Text(
                        source.disabledReason == null
                            ? source.label
                            : '${source.label} · ${source.disabledReason}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: source.disabled ? Colors.white24 : null),
                      ),
                    )),
            ],
            onChanged: (value) {
              if (value != null) onSourceChanged(value);
            },
          ),
          if (device.isAudioRoute) ...[
            const SizedBox(height: 9),
            RotaryKnob(
              label: 'Mix',
              value: device.routeMix,
              size: DeviceStripMetrics.dynamicsFxKnobSize,
              displayValue: '${(device.routeMix * 100).round()}%',
              accentColor: accent,
              modulationActive: modulatedParams.contains('routeMix'),
              automationActive: automatedParams.contains('routeMix'),
              modulationAmount: modulationAmounts['routeMix'] ?? 0,
              connectModeActive: connectModeLfoId != null,
              onModulationAssign: onModulationAssign == null
                  ? null
                  : (amount) => onModulationAssign!('routeMix', amount),
              linkModeActive: automationLinkActive,
              onLinkTap: onAutomationLinkTap == null
                  ? null
                  : () => onAutomationLinkTap!('routeMix'),
              onAutomateRequest: onAutomateParameter == null
                  ? null
                  : () => onAutomateParameter!('routeMix'),
              onChanged: (value) => onParameterChanged('routeMix', value),
            ),
          ],
        ],
      ),
    );
  }
}
