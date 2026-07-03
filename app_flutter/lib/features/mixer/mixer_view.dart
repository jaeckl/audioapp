import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/live_meters_dto.dart';
import '../../bridge/project_snapshot.dart';
import '../arrangement/track_lane_icon.dart';
import '../device_strip/device_knob_sizes.dart';
import '../device_strip/rotary_knob.dart';

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

class _TrackChannel extends StatelessWidget {
  const _TrackChannel({
    required this.track,
    required this.icon,
    required this.selected,
    required this.meter,
    required this.onGainChanged,
    required this.onPanChanged,
    required this.onSelect,
    required this.onMute,
    required this.onSolo,
  });

  final TrackSnapshot track;
  final IconData icon;
  final bool selected;
  final DeviceMeterReading? meter;
  final ValueChanged<double> onGainChanged, onPanChanged;
  final VoidCallback onSelect, onMute, onSolo;

  @override
  Widget build(BuildContext context) {
    final device = track.trackGainDevice;
    final accent = selected ? const Color(0xFFE8A54B) : const Color(0xFF777787);
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: 84,
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF23232D) : const Color(0xFF191920),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: selected ? accent : Colors.white10),
        ),
        child: Column(
          children: [
            Row(children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 3),
              Expanded(
                child: Text(track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Colors.white70)),
              ),
            ]),
            const SizedBox(height: 3),
            Expanded(
              child: Row(
                children: [
                  _StereoMeter(
                    left: meter?.leftLevel ?? 0,
                    right: meter?.rightLevel ?? 0,
                  ),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          activeTrackColor: accent,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white70,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: (device?.gain ?? 1).clamp(0.0, 1.0),
                          onChanged: onGainChanged,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            RotaryKnob(
              label: 'Pan',
              value: (device?.pan ?? .5).clamp(0.0, 1.0),
              displayValue: _panLabel(device?.pan ?? .5),
              accentColor: accent,
              size: DeviceKnobSizes.compact,
              onChanged: onPanChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MixToggle(
                    label: 'M',
                    active: track.muted,
                    color: Colors.orange,
                    onTap: onMute),
                const SizedBox(width: 4),
                _MixToggle(
                    label: 'S',
                    active: track.soloed,
                    color: Colors.amber,
                    onTap: onSolo),
                const SizedBox(width: 4),
                Text('${track.visibleDevices.length}',
                    style: const TextStyle(fontSize: 8, color: Colors.white38)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterChannel extends StatelessWidget {
  const _MasterChannel(
      {required this.title, required this.gain, required this.onGainChanged});
  final String title;
  final double gain;
  final ValueChanged<double> onGainChanged;

  @override
  Widget build(BuildContext context) => Container(
        width: 74,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF28241A),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.amber.withValues(alpha: .35)),
        ),
        child: Column(children: [
          const Icon(Icons.speaker, size: 15, color: Colors.amber),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Colors.white70)),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child:
                  Slider(value: gain.clamp(0.0, 1.0), onChanged: onGainChanged),
            ),
          ),
          Text('${(gain * 100).round()}%',
              style: const TextStyle(fontSize: 9, color: Colors.white54)),
        ]),
      );
}

class _StereoMeter extends StatelessWidget {
  const _StereoMeter({required this.left, required this.right});
  final double left, right;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 14,
        child: Row(children: [
          _bar(left),
          const SizedBox(width: 2),
          _bar(right),
        ]),
      );

  Widget _bar(double value) => Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final level = math.sqrt(value.clamp(0.0, 1.0));
            final color = value >= 1
                ? Colors.redAccent
                : value > .72
                    ? Colors.amber
                    : const Color(0xFF65D68B);
            return Stack(alignment: Alignment.bottomCenter, children: [
              Container(color: Colors.black38),
              FractionallySizedBox(
                heightFactor: level,
                child: Container(color: color),
              ),
            ]);
          },
        ),
      );
}

class _MixToggle extends StatelessWidget {
  const _MixToggle(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          width: 20,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: .25) : Colors.white10,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: active ? color : Colors.white54,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

String _panLabel(double pan) {
  final amount = ((pan - .5).abs() * 200).round();
  if (amount == 0) return 'C';
  return pan < .5 ? 'L$amount' : 'R$amount';
}
