import 'package:flutter/material.dart';

/// Payload for reordering a top-level track device via tool-rail drag.
class DeviceDragData {
  const DeviceDragData({
    required this.trackId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.accentColor,
    required this.visibleIndex,
    required this.feedbackWidth,
    required this.feedbackHeight,
  });

  final String trackId;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final Color accentColor;
  final int visibleIndex;
  final double feedbackWidth;
  final double feedbackHeight;
}
