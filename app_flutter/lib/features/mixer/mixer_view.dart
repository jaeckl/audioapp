import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/live_meters_dto.dart';
import '../../bridge/project_snapshot.dart';
import '../arrangement/track_lane_icon.dart';
import '../device_strip/device_knob_sizes.dart';
import '../device_strip/rotary_knob.dart';

part 'mixer_view_track_channel.dart';
part 'mixer_view_master_channel.dart';
part 'mixer_view_stereo_meter.dart';
part 'mixer_view_mix_toggle.dart';

class MixerView extends StatelessWidget {
  const MixerView({
    super.key,
    required this.snapshot,
    required this.liveMeters,
    required this.onTrackGainChanged,
    required this.onTrackPanChanged,
    required this.onTrackMuted,
    required this.onTrackSoloed,
    required this.onTrackSelected,
    required this.onMasterGainChanged,
  });

  static const double panelHeight = 272;
  final ProjectSnapshot snapshot;
  final ValueListenable<Map<String, DeviceMeterReading>> liveMeters;
  final void Function(String deviceId, double gain) onTrackGainChanged;
  final void Function(String deviceId, double pan) onTrackPanChanged;
  final void Function(String trackId, bool muted) onTrackMuted;
  final void Function(String trackId, bool soloed) onTrackSoloed;
  final ValueChanged<String> onTrackSelected;
  final ValueChanged<double> onMasterGainChanged;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF121218),
        child: SizedBox(
          height: panelHeight,
          child: ValueListenableBuilder<Map<String, DeviceMeterReading>>(
            valueListenable: liveMeters,
            builder: (context, meters, _) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              children: [
                for (var i = 0; i < snapshot.tracks.length; i++)
                  _TrackChannel(
                    track: snapshot.tracks[i],
                    icon: TrackLaneIcon.iconForTrack(snapshot.tracks[i], i),
                    selected: snapshot.tracks[i].id == snapshot.selectedTrackId,
                    meter: snapshot.tracks[i].trackGainDevice == null
                        ? null
                        : meters[snapshot.tracks[i].trackGainDevice!.id],
                    onGainChanged: (value) {
                      final device = snapshot.tracks[i].trackGainDevice;
                      if (device != null) onTrackGainChanged(device.id, value);
                    },
                    onPanChanged: (value) {
                      final device = snapshot.tracks[i].trackGainDevice;
                      if (device != null) onTrackPanChanged(device.id, value);
                    },
                    onSelect: () => onTrackSelected(snapshot.tracks[i].id),
                    onMute: () => onTrackMuted(
                        snapshot.tracks[i].id, !snapshot.tracks[i].muted),
                    onSolo: () => onTrackSoloed(
                        snapshot.tracks[i].id, !snapshot.tracks[i].soloed),
                  ),
                _MasterChannel(
                  title: snapshot.master.name,
                  gain: snapshot.master.gain,
                  onGainChanged: onMasterGainChanged,
                ),
              ],
            ),
          ),
        ),
      );
}

String _panLabel(double pan) {
  final amount = ((pan - .5).abs() * 200).round();
  if (amount == 0) return 'C';
  return pan < .5 ? 'L$amount' : 'R$amount';
}
