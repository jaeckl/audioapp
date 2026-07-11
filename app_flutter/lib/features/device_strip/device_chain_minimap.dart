import 'dart:ui';

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_chain_layout.dart';
import 'device_strip_card.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';
import 'device_strip_theme.dart';

part 'device_chain_minimap_device_chain_minimap_state.dart';
part 'device_chain_minimap_minimap_chain_preview.dart';

/// Scrubbable minimap of the fullscreen device chain.
class DeviceChainMinimap extends StatefulWidget {
  const DeviceChainMinimap({
    super.key,
    required this.track,
    required this.scrollController,
    required this.density,
  });

  final TrackSnapshot track;
  final ScrollController scrollController;
  final DeviceStripSlotDensity density;

  @override
  State<DeviceChainMinimap> createState() => _DeviceChainMinimapState();
}
