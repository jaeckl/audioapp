import 'package:flutter/material.dart';

/// Payload for reordering a top-level track device via tool-rail drag.
class DeviceDragData {
  const DeviceDragData({
    required this.trackId,
    required this.deviceId,
    required this.deviceName,
    required this.accentColor,
    required this.visibleIndex,
  });

  final String trackId;
  final String deviceId;
  final String deviceName;
  final Color accentColor;
  final int visibleIndex;
}
