import '../../bridge/device_capabilities.dart';
import '../../bridge/project_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';

/// UI-local expand maps for virtual sub-strip hosts (not persisted).
class DeviceChainExpandState {
  const DeviceChainExpandState({
    this.synthAudioFxExpanded = const {},
    this.synthNoteFxExpanded = const {},
    this.splitBranchExpanded = const {},
    this.mbBandExpanded = const {},
    this.slBandExpanded = const {},
    this.drumChainExpandedFor,
    this.drumSelectedNoteFor,
  });

  static const empty = DeviceChainExpandState();

  final Map<String, bool> synthAudioFxExpanded;
  final Map<String, bool> synthNoteFxExpanded;
  final Map<String, Set<int>> splitBranchExpanded;
  final Map<String, Set<int>> mbBandExpanded;
  final Map<String, Set<int>> slBandExpanded;
  final bool Function(String deviceId)? drumChainExpandedFor;
  final int Function(String deviceId)? drumSelectedNoteFor;

  bool isSplitBranchExpanded(String deviceId, int branchIndex) =>
      splitBranchExpanded[deviceId]?.contains(branchIndex) ?? false;

  bool isMbBandExpanded(String deviceId, int bandIndex) =>
      mbBandExpanded[deviceId]?.contains(bandIndex) ?? false;

  bool isSlBandExpanded(String deviceId, int bandIndex) =>
      slBandExpanded[deviceId]?.contains(bandIndex) ?? false;

  bool isSynthAudioFxExpanded(String deviceId) =>
      synthAudioFxExpanded[deviceId] ?? false;

  bool isSynthNoteFxExpanded(String deviceId) =>
      synthNoteFxExpanded[deviceId] ?? false;

  bool isDrumChainExpanded(String deviceId) =>
      drumChainExpandedFor?.call(deviceId) ?? true;
}

/// Width/layout helpers for the horizontal device chain.
abstract final class DeviceChainLayout {
  /// Bracket stroke width (shared with `_VirtualChainBracketPainter`).
  static const virtualStripBracketStroke = 1.5;
  /// Strip-background cut pillars = 2× bracket stroke.
  static const virtualStripCutWidth = virtualStripBracketStroke * 2;
  static const virtualStripOuterPadding = 2.0;
  static const virtualStripInnerPaddingH = 18.0;
  static const virtualStripTitleWidth = 20.0;
  static const virtualStripTitleGap = 7.0;
  static const _virtualStripChildGap = 5.0;

  static bool _isSynthHost(String type) =>
      DeviceCapabilities.virtualStripHosts.contains(type) ||
      type == 'spectral_loud_split';

  static double slotWidthFor(
      DeviceSnapshot device, DeviceStripSlotDensity density) {
    final cardWidth = DeviceStripMetrics.designWidthFor(
      device.type,
      collapsed: density == DeviceStripSlotDensity.collapsed,
    );
    if (density == DeviceStripSlotDensity.collapsed) {
      return cardWidth;
    }
    return cardWidth +
        DeviceStripMetrics.toolRailWidth +
        DeviceStripMetrics.inputPanelWidthFor(device.type) +
        DeviceStripMetrics.outputPanelWidthFor(device.type);
  }

  static double _virtualStripChromeWidth() =>
      virtualStripOuterPadding +
      virtualStripInnerPaddingH +
      virtualStripTitleWidth +
      virtualStripTitleGap;

  /// Width of cut pillars wrapping a nested (or post-host) virtual strip.
  static double virtualStripInterruptWidth() => virtualStripCutWidth * 2;

  static double _virtualStripListWidth(
    List<DeviceSnapshot> devices,
    DeviceStripSlotDensity density,
    DeviceChainExpandState expand, {
    required int maxDevices,
    required bool showInsertWhenUnderCap,
  }) {
    // Interrupt pillars wrap every emitted virtual strip (parent bracket cut).
    var width = _virtualStripChromeWidth() + virtualStripInterruptWidth();
    for (final child in devices) {
      width += slotWidthFor(child, density);
      width += virtualRegionsWidthFor(child, density, expand);
      width += _virtualStripChildGap;
    }
    if (showInsertWhenUnderCap && devices.length < maxDevices) {
      width += DeviceStripMetrics.separatorWidth;
    }
    return width;
  }

  /// Width of virtual sub-strips emitted after [device] when expanded.
  static double virtualRegionsWidthFor(
    DeviceSnapshot device,
    DeviceStripSlotDensity density,
    DeviceChainExpandState expand,
  ) {
    var width = 0.0;

    if (device is DrumMachineDeviceSnapshot && expand.isDrumChainExpanded(device.id)) {
      final note = expand.drumSelectedNoteFor?.call(device.id) ?? 36;
      final pad = device.padForNote(note);
      width += _virtualStripListWidth(
        pad.devices,
        density,
        expand,
        maxDevices: 4,
        showInsertWhenUnderCap: true,
      );
    }

    if (device is ChainDeviceSnapshot) {
      width += _virtualStripListWidth(
        device.devices,
        density,
        expand,
        maxDevices: 8,
        showInsertWhenUnderCap: true,
      );
    }

    if (device is SplitDeviceSnapshot) {
      for (var branch = 0; branch < 2; branch++) {
        if (!expand.isSplitBranchExpanded(device.id, branch)) continue;
        width += _virtualStripListWidth(
          device.branchDevices(branch),
          density,
          expand,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
    }

    if (device is MultibandSplitDeviceSnapshot) {
      for (var band = 0; band < device.bandCount; band++) {
        if (!expand.isMbBandExpanded(device.id, band)) continue;
        width += _virtualStripListWidth(
          device.bandDevices(band),
          density,
          expand,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
    }

    if (device is SpectralLoudSplitDeviceSnapshot) {
      for (var band = 0; band < 3; band++) {
        if (!expand.isSlBandExpanded(device.id, band)) continue;
        width += _virtualStripListWidth(
          device.bandDevices(band),
          density,
          expand,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
      if (expand.isSynthNoteFxExpanded(device.id)) {
        width += _virtualStripListWidth(
          device.preFxDevices,
          density,
          expand,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
      if (expand.isSynthAudioFxExpanded(device.id)) {
        width += _virtualStripListWidth(
          device.postFxDevices,
          density,
          expand,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
    }

    if (_isSynthHost(device.type) &&
        device is! SpectralLoudSplitDeviceSnapshot) {
      if (expand.isSynthAudioFxExpanded(device.id)) {
        width += _virtualStripListWidth(
          device.audioFxDevices,
          density,
          expand,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
      if (expand.isSynthNoteFxExpanded(device.id)) {
        width += _virtualStripListWidth(
          device.noteFxDevices,
          density,
          expand,
          maxDevices: 8,
          showInsertWhenUnderCap: true,
        );
      }
    }

    return width;
  }

  /// Total scrollable content width including list horizontal padding.
  static double contentWidth(
    TrackSnapshot track,
    DeviceStripSlotDensity density, {
    double horizontalPadding = 16,
    DeviceChainExpandState expand = DeviceChainExpandState.empty,
  }) {
    final devices = track.visibleDevices.toList();
    if (devices.isEmpty) {
      return DeviceStripMetrics.separatorWidth + 120 + horizontalPadding;
    }

    var width = horizontalPadding;
    for (final device in devices) {
      width += slotWidthFor(device, density);
      width += virtualRegionsWidthFor(device, density, expand);
      width += DeviceStripMetrics.separatorWidth;
    }
    return width;
  }
}
