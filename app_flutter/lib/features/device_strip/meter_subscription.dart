import 'package:flutter/widgets.dart';

import '../../bridge/project_snapshot.dart';
import 'device_chain_layout.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';

/// Which devices should receive live meter / analyzer updates from the engine.
abstract final class MeterSubscription {
  static const _analysisTypes = {
    'oscilloscope',
    'spectrum_analyzer',
    'loudness_meter',
    'stereo_imager',
  };

  static const _dynamicsTypes = {
    'gate',
    'compressor',
    'expander',
    'limiter',
  };

  /// Split devices publish post-gain peaks per branch (L/Mid → left, R/Side → right).
  static const _splitTypes = {
    'lr_split',
    'ms_split',
    'mb_split_2',
    'mb_split_3',
    'mb_split_4',
    'spectral_loud_split',
  };

  static bool publishesLiveMeters(String deviceType) =>
      _analysisTypes.contains(deviceType) ||
      _dynamicsTypes.contains(deviceType) ||
      _splitTypes.contains(deviceType);

  /// Device IDs on [track] that overlap the horizontal viewport and publish meters.
  static List<String> visibleMeterDeviceIds({
    required TrackSnapshot track,
    required DeviceStripSlotDensity density,
    required ScrollController scrollController,
    required double viewportWidth,
    double listPadding = 8,
  }) {
    if (viewportWidth <= 0) {
      return const [];
    }

    final devices = track.visibleDevices.toList();
    if (devices.isEmpty) {
      return const [];
    }

    final scrollOffset =
        scrollController.hasClients ? scrollController.offset : 0.0;
    final viewStart = scrollOffset;
    final viewEnd = scrollOffset + viewportWidth;

    final ids = <String>[];
    var x = listPadding;
    for (final device in devices) {
      final slotWidth = DeviceChainLayout.slotWidthFor(device, density);
      final slotStart = x;
      final slotEnd = x + slotWidth;
      if (slotEnd > viewStart && slotStart < viewEnd &&
          publishesLiveMeters(device.type)) {
        ids.add(device.id);
      }
      x += slotWidth + DeviceStripMetrics.separatorWidth;
    }
    return ids;
  }
}
