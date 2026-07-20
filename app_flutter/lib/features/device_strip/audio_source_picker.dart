import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../arrangement/track_lane_icon.dart';
import 'device_strip_theme.dart';
import 'routing_device_panel.dart';

/// Combobox row for sidechain / audio source pick with track icons.
class AudioSourcePicker extends StatelessWidget {
  const AudioSourcePicker({
    super.key,
    required this.sources,
    required this.selectedId,
    required this.onChanged,
    required this.accent,
    required this.tracks,
  });

  final List<RoutingSourceOption> sources;
  final String selectedId;
  final ValueChanged<String> onChanged;
  final Color accent;
  final List<TrackSnapshot> tracks;

  IconData _iconFor(RoutingSourceOption source) {
    final index = tracks.indexWhere((t) => t.id == source.trackId);
    if (index < 0) return Icons.audiotrack;
    return TrackLaneIcon.iconForTrack(tracks[index], index);
  }

  @override
  Widget build(BuildContext context) {
    final value = sources.any((s) => s.id == selectedId) ? selectedId : '';
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF1A1A22),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.4)),
        ),
      ),
      items: [
        for (final source in sources)
          DropdownMenuItem<String>(
            value: source.id,
            enabled: !source.disabled,
            child: Row(
              children: [
                if (source.id.isNotEmpty) ...[
                  Icon(_iconFor(source), size: 14, color: accent),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    source.disabled && source.disabledReason != null
                        ? '${source.label} (${source.disabledReason})'
                        : source.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: source.disabled
                          ? Colors.white38
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: (next) {
        if (next == null) return;
        final match = sources.where((s) => s.id == next).firstOrNull;
        if (match != null && match.disabled) return;
        onChanged(next);
      },
    );
  }
}

/// Sidechain source list for Ducker (Off + track outputs + devices).
List<RoutingSourceOption> buildSidechainSourceOptions(
  ProjectSnapshot snapshot,
  TrackSnapshot destinationTrack,
  DeviceSnapshot ducker,
) {
  final tracks = [
    for (final track in snapshot.tracks)
      track.id == destinationTrack.id ? destinationTrack : track,
  ];
  final raw = <RoutingSourceOption>[
    const RoutingSourceOption(
      id: '',
      label: 'Off',
      isMidi: false,
      trackId: '',
      deviceIndex: -1,
    ),
  ];

  for (final track in tracks) {
    if (track.id == destinationTrack.id) continue;
    raw.add(RoutingSourceOption(
      id: 'track-audio:${track.id}',
      label: track.name,
      isMidi: false,
      trackId: track.id,
      deviceIndex: -1,
    ));
    for (var index = 0; index < track.devices.length; index++) {
      final device = track.devices[index];
      if (device.type == 'audio_receiver' ||
          device.type == 'midi_receiver' ||
          device.type == 'midi_delay') {
        continue;
      }
      raw.add(RoutingSourceOption(
        id: device.id,
        label:
            '${track.name} · ${DeviceStripTheme.labelForDeviceType(device.type)}',
        isMidi: false,
        trackId: track.id,
        deviceIndex: index,
      ));
    }
  }

  final sourceById = {for (final source in raw) source.id: source};
  final adjacency = <String, Set<String>>{};
  for (final track in tracks) {
    if (track.parentGroupId.isNotEmpty) {
      adjacency.putIfAbsent(track.id, () => <String>{}).add(track.parentGroupId);
    }
  }
  for (final track in tracks) {
    for (final device in track.devices) {
      String sourceId = '';
      if (device is RoutingDeviceSnapshot && device.sourceId.isNotEmpty) {
        sourceId = device.sourceId;
      } else if (device is DuckerDeviceSnapshot &&
          device.sidechainSourceId.isNotEmpty) {
        sourceId = device.sidechainSourceId;
      }
      if (sourceId.isEmpty || device.id == ducker.id) continue;
      final source = sourceById[sourceId] ??
          (sourceId.startsWith('track-audio:')
              ? RoutingSourceOption(
                  id: sourceId,
                  label: '',
                  isMidi: false,
                  trackId: sourceId.substring('track-audio:'.length),
                  deviceIndex: -1,
                )
              : null);
      if (source != null && source.trackId.isNotEmpty && source.trackId != track.id) {
        adjacency.putIfAbsent(source.trackId, () => <String>{}).add(track.id);
      }
    }
  }

  bool reaches(String from, String target, Set<String> seen) {
    if (from == target) return true;
    if (!seen.add(from)) return false;
    return adjacency[from]?.any((next) => reaches(next, target, seen)) ?? false;
  }

  return raw.map((source) {
    String? reason;
    if (source.id.isNotEmpty &&
        source.trackId.isNotEmpty &&
        reaches(destinationTrack.id, source.trackId, <String>{})) {
      reason = 'would create cycle';
    }
    return RoutingSourceOption(
      id: source.id,
      label: source.label,
      isMidi: false,
      trackId: source.trackId,
      deviceIndex: source.deviceIndex,
      disabled: reason != null,
      disabledReason: reason,
    );
  }).toList();
}
