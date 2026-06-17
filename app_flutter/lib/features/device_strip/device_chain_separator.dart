import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_insert_slot.dart';
import 'device_strip_metrics.dart';
import 'device_vu_meter.dart';

/// VU meter with centered insert button between device chain slots.
class DeviceChainSeparator extends StatelessWidget {
  const DeviceChainSeparator({
    super.key,
    required this.active,
    required this.gain,
    required this.onInsert,
  });

  final bool active;
  final double gain;
  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DeviceStripMetrics.separatorWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DeviceVuMeter(active: active, gain: gain),
              ),
            ),
            DeviceInsertSlot(onPressed: onInsert),
          ],
        ),
      ),
    );
  }
}

/// Maps a visible-device index to an engine insert index (before track_gain).
int deviceInsertIndexAfter(TrackSnapshot track, int visibleDeviceIndex) {
  final devices = track.devices;
  final visible = track.visibleDevices.toList();
  if (visible.isEmpty) return 0;
  if (visibleDeviceIndex < 0) return 0;

  final DeviceSnapshot anchor = visibleDeviceIndex >= visible.length
      ? visible.last
      : visible[visibleDeviceIndex];

  final anchorIndex = devices.indexWhere((device) => device.id == anchor.id);
  if (anchorIndex < 0) return devices.length;
  return anchorIndex + 1;
}

double _deviceGain(DeviceSnapshot device) {
  return switch (device.type) {
    'simple_sampler' => device.gain,
    'simple_oscillator' => 0.85,
    'subtractive_synth' => device.gain,
    _ => 0.5,
  };
}

/// Shared insert-index + gain helpers for chain rows.
extension DeviceChainSeparatorMetrics on DeviceSnapshot {
  double get chainVuGain => _deviceGain(this);
}
