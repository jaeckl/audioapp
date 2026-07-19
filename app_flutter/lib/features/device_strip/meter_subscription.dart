import 'package:flutter/widgets.dart';

import '../../bridge/device_capabilities.dart';
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

  static bool _isSynthHost(String type) =>
      DeviceCapabilities.virtualStripHosts.contains(type) ||
      type == 'spectral_loud_split';

  static bool _overlapsViewport(
    double slotStart,
    double slotEnd,
    double viewStart,
    double viewEnd,
  ) =>
      slotEnd > viewStart && slotStart < viewEnd;

  static void _maybeAddPublisher(
    DeviceSnapshot device,
    double slotStart,
    double slotEnd,
    double viewStart,
    double viewEnd,
    List<String> ids,
  ) {
    if (_overlapsViewport(slotStart, slotEnd, viewStart, viewEnd) &&
        publishesLiveMeters(device.type)) {
      ids.add(device.id);
    }
  }

  /// Walk [devices] laid out as a virtual sub-strip (must match [DeviceChainLayout]).
  static double _walkVirtualStripList(
    List<DeviceSnapshot> devices,
    DeviceStripSlotDensity density,
    DeviceChainExpandState expand,
    double x,
    double viewStart,
    double viewEnd,
    List<String> ids, {
    required int maxDevices,
    required bool showInsertWhenUnderCap,
  }) {
    const chromeWidth = 2.0 + 18.0 + 20.0;
    x += chromeWidth;
    for (final device in devices) {
      final slotWidth = DeviceChainLayout.slotWidthFor(device, density);
      _maybeAddPublisher(device, x, x + slotWidth, viewStart, viewEnd, ids);
      x += slotWidth;
      x = _walkVirtualRegions(device, density, expand, x, viewStart, viewEnd, ids);
      x += 5;
    }
    if (showInsertWhenUnderCap && devices.length < maxDevices) {
      x += DeviceStripMetrics.separatorWidth;
    }
    return x;
  }

  static double _walkVirtualRegions(
    DeviceSnapshot device,
    DeviceStripSlotDensity density,
    DeviceChainExpandState expand,
    double x,
    double viewStart,
    double viewEnd,
    List<String> ids,
  ) {
    if (device is DrumMachineDeviceSnapshot && expand.isDrumChainExpanded(device.id)) {
      final note = expand.drumSelectedNoteFor?.call(device.id) ?? 36;
      x = _walkVirtualStripList(
        device.padForNote(note).devices,
        density,
        expand,
        x,
        viewStart,
        viewEnd,
        ids,
        maxDevices: 4,
        showInsertWhenUnderCap: true,
      );
    }

    if (device is ChainDeviceSnapshot) {
      x = _walkVirtualStripList(
        device.devices,
        density,
        expand,
        x,
        viewStart,
        viewEnd,
        ids,
        maxDevices: 8,
        showInsertWhenUnderCap: true,
      );
    }

    if (device is SplitDeviceSnapshot) {
      for (var branch = 0; branch < 2; branch++) {
        if (!expand.isSplitBranchExpanded(device.id, branch)) continue;
        x = _walkVirtualStripList(
          device.branchDevices(branch),
          density,
          expand,
          x,
          viewStart,
          viewEnd,
          ids,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
    }

    if (device is MultibandSplitDeviceSnapshot) {
      for (var band = 0; band < device.bandCount; band++) {
        if (!expand.isMbBandExpanded(device.id, band)) continue;
        x = _walkVirtualStripList(
          device.bandDevices(band),
          density,
          expand,
          x,
          viewStart,
          viewEnd,
          ids,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
    }

    if (device is SpectralLoudSplitDeviceSnapshot) {
      for (var band = 0; band < 3; band++) {
        if (!expand.isSlBandExpanded(device.id, band)) continue;
        x = _walkVirtualStripList(
          device.bandDevices(band),
          density,
          expand,
          x,
          viewStart,
          viewEnd,
          ids,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
      if (expand.isSynthNoteFxExpanded(device.id)) {
        x = _walkVirtualStripList(
          device.preFxDevices,
          density,
          expand,
          x,
          viewStart,
          viewEnd,
          ids,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
      if (expand.isSynthAudioFxExpanded(device.id)) {
        x = _walkVirtualStripList(
          device.postFxDevices,
          density,
          expand,
          x,
          viewStart,
          viewEnd,
          ids,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
    }

    if (_isSynthHost(device.type) &&
        device is! SpectralLoudSplitDeviceSnapshot &&
        device is VirtualStripHostSnapshot) {
      final host = device;
      if (expand.isSynthAudioFxExpanded(device.id)) {
        x = _walkVirtualStripList(
          host.audioFxDevices,
          density,
          expand,
          x,
          viewStart,
          viewEnd,
          ids,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
      if (expand.isSynthNoteFxExpanded(device.id)) {
        x = _walkVirtualStripList(
          host.noteFxDevices,
          density,
          expand,
          x,
          viewStart,
          viewEnd,
          ids,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
    }

    return x;
  }

  /// Device IDs on [track] that overlap the horizontal viewport and publish meters.
  ///
  /// Walks top-level slots and recursively includes nested publishers inside
  /// expanded virtual sub-strips (see [DeviceChainExpandState]).
  static List<String> visibleMeterDeviceIds({
    required TrackSnapshot track,
    required DeviceStripSlotDensity density,
    required ScrollController scrollController,
    required double viewportWidth,
    double listPadding = 8,
    DeviceChainExpandState expand = DeviceChainExpandState.empty,
    Set<String> expandedDeviceIds = const {},
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
      if (expandedDeviceIds.isNotEmpty &&
          DeviceCapabilities.virtualStripHosts.contains(device.type) &&
          !expandedDeviceIds.contains(device.id)) {
        final slotWidth = DeviceChainLayout.slotWidthFor(device, density);
        x += slotWidth + DeviceStripMetrics.separatorWidth;
        continue;
      }

      final slotWidth = DeviceChainLayout.slotWidthFor(device, density);
      _maybeAddPublisher(device, x, x + slotWidth, viewStart, viewEnd, ids);
      x += slotWidth;
      x = _walkVirtualRegions(device, density, expand, x, viewStart, viewEnd, ids);
      x += DeviceStripMetrics.separatorWidth;
    }
    return ids;
  }
}
