import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../arrangement/track_lane_icon.dart';
import '../device_strip/device_knob_sizes.dart';
import '../device_strip/rotary_knob.dart';

class MixerView extends StatelessWidget {
  const MixerView({
    super.key,
    required this.snapshot,
    required this.onTrackGainChanged,
    required this.onMasterGainChanged,
  });

  final ProjectSnapshot snapshot;
  final void Function(String deviceId, double gain) onTrackGainChanged;
  final ValueChanged<double> onMasterGainChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Mixer', style: theme.textTheme.titleMedium),
        ),
        Expanded(
          child: snapshot.tracks.isEmpty
              ? Center(
                  child: Text(
                    'No tracks — add tracks in Arrangement',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
                  ),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (var i = 0; i < snapshot.tracks.length; i++)
                      _MixerColumn(
                        title: snapshot.tracks[i].name,
                        icon: TrackLaneIcon.iconForTrack(snapshot.tracks[i], i),
                        gain: snapshot.tracks[i].trackGainDevice?.gain ?? 1.0,
                        onGainChanged: (value) {
                          final device = snapshot.tracks[i].trackGainDevice;
                          if (device != null) {
                            onTrackGainChanged(device.id, value);
                          }
                        },
                      ),
                    _MixerColumn(
                      title: snapshot.master.name,
                      icon: Icons.speaker_outlined,
                      accent: Colors.amber.shade100,
                      gain: snapshot.master.gain,
                      onGainChanged: onMasterGainChanged,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MixerColumn extends StatelessWidget {
  const _MixerColumn({
    required this.title,
    required this.icon,
    required this.gain,
    required this.onGainChanged,
    this.accent,
  });

  final String title;
  final IconData icon;
  final double gain;
  final ValueChanged<double> onGainChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 88,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: accent ?? theme.colorScheme.secondary),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
          const Spacer(),
          RotaryKnob(
            label: 'Gain',
            value: gain.clamp(0.0, 1.0),
            size: DeviceKnobSizes.mixer,
            displayValue: '${(gain * 100).round()}%',
            accentColor: accent ?? const Color(0xFFE8A54B),
            onChanged: onGainChanged,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
