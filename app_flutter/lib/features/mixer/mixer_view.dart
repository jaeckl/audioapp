import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/live_meters_dto.dart';
import '../../bridge/project_snapshot.dart';
import '../arrangement/track_lane_color.dart';
import '../arrangement/track_lane_icon.dart';
import 'mixer_theme.dart';

part 'mixer_view_channel_frame.dart';
part 'mixer_view_engraved_paint.dart';
part 'mixer_view_track_channel.dart';
part 'mixer_view_master_channel.dart';
part 'mixer_view_stereo_meter.dart';
part 'mixer_view_fader.dart';
part 'mixer_view_pan_slider.dart';
part 'mixer_view_mix_button_row.dart';
part 'mixer_view_output_destinations.dart';
part 'mixer_view_output_menu.dart';

class MixerView extends StatelessWidget {
  const MixerView({
    super.key,
    required this.snapshot,
    required this.liveMeters,
    required this.onTrackGainChanged,
    required this.onTrackPanChanged,
    required this.onTrackMuted,
    required this.onTrackSoloed,
    required this.onTrackRecordArmed,
    required this.onTrackSelected,
    required this.onMasterGainChanged,
    required this.onTrackOutputChanged,
  });

  static const double panelHeight = MixerTheme.panelHeight;

  final ProjectSnapshot snapshot;
  final ValueListenable<Map<String, DeviceMeterReading>> liveMeters;
  final void Function(String deviceId, double gain) onTrackGainChanged;
  final void Function(String deviceId, double pan) onTrackPanChanged;
  final void Function(String trackId, bool muted) onTrackMuted;
  final void Function(String trackId, bool soloed) onTrackSoloed;
  final void Function(String trackId, bool armed) onTrackRecordArmed;
  final ValueChanged<String> onTrackSelected;
  final ValueChanged<double> onMasterGainChanged;
  final void Function(String trackId, String outputTarget) onTrackOutputChanged;

  @override
  Widget build(BuildContext context) => Material(
        color: MixerTheme.panelBackground,
        child: SizedBox(
          height: panelHeight,
          child: ValueListenableBuilder<Map<String, DeviceMeterReading>>(
            valueListenable: liveMeters,
            builder: (context, meters, _) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              children: [
                for (var i = 0; i < snapshot.tracks.length; i++)
                  _TrackChannel(
                    track: snapshot.tracks[i],
                    icon: TrackLaneIcon.iconForTrack(snapshot.tracks[i], i),
                    accent: TrackLaneColor.colorForTrack(snapshot.tracks[i], i),
                    selected:
                        snapshot.tracks[i].id == snapshot.selectedTrackId,
                    recordArmed: snapshot.tracks[i].id ==
                            snapshot.selectedTrackId &&
                        snapshot.recordArmed,
                    meter: snapshot.tracks[i].trackGainDevice == null
                        ? null
                        : meters[snapshot.tracks[i].trackGainDevice!.id],
                    outputChoices: _outputChoicesFor(
                      snapshot: snapshot,
                      selfId: snapshot.tracks[i].id,
                    ),
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
                      snapshot.tracks[i].id,
                      !snapshot.tracks[i].muted,
                    ),
                    onSolo: () => onTrackSoloed(
                      snapshot.tracks[i].id,
                      !snapshot.tracks[i].soloed,
                    ),
                    onRecord: () => onTrackRecordArmed(
                      snapshot.tracks[i].id,
                      !(snapshot.tracks[i].id == snapshot.selectedTrackId &&
                          snapshot.recordArmed),
                    ),
                    onOutputChanged: (target) =>
                        onTrackOutputChanged(snapshot.tracks[i].id, target),
                  ),
                _MasterChannel(
                  title: snapshot.master.name,
                  gain: snapshot.master.gain,
                  muted: snapshot.master.muted,
                  selected: snapshot.selectedTrackId == 'master',
                  meter: meters['master'],
                  onGainChanged: onMasterGainChanged,
                  onSelect: () => onTrackSelected('master'),
                  onMute: () =>
                      onTrackMuted('master', !snapshot.master.muted),
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
