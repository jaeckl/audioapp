import 'package:flutter/services.dart';

/// User-facing NestingError text for snackbars (bridge code → message).
String nestingErrorSnackMessage(Object error) {
  if (error is! PlatformException) return error.toString();
  switch (error.code) {
    case 'branch_device_cap':
      return 'This strip is full (max 8 devices).';
    case 'pad_device_cap':
      return 'This drum pad is full (max 4 devices).';
    case 'track_device_cap':
      return 'Track device limit reached (max 24).';
    case 'ring_lease_exhausted':
      return 'Too many time-based/buffer effects on this track.';
    case 'subgraph_step_overflow':
      return 'Device graph too deep/complex for this track.';
    case 'unknown_parent':
      return 'Parent device not found.';
    case 'unknown_type':
      return 'Unknown device type.';
    default:
      return error.message ?? error.code;
  }
}
