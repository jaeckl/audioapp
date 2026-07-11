import 'package:flutter/material.dart';

part 'transport_overflow_sheet_tap_tempo.dart';
part 'transport_overflow_sheet_private_transport_overflow_sheet_state.dart';

/// Tap-tempo helper — averages last intervals between taps.
/// Overflow actions for transport (tap tempo, loop toggle, export).
class TransportOverflowSheet extends StatefulWidget {
  const TransportOverflowSheet({
    super.key,
    required this.bpm,
    required this.loopEnabled,
    required this.followPlayheadEnabled,
    required this.followPlayheadSuspended,
    required this.onBpmChanged,
    required this.onLoopToggled,
    required this.onFollowPlayheadToggled,
    this.onExportMix,
  });

  final int bpm;
  final bool loopEnabled;
  final bool followPlayheadEnabled;
  final bool followPlayheadSuspended;
  final ValueChanged<int> onBpmChanged;
  final ValueChanged<bool> onLoopToggled;
  final ValueChanged<bool> onFollowPlayheadToggled;
  final VoidCallback? onExportMix;

  @override
  State<TransportOverflowSheet> createState() => _TransportOverflowSheetState();
}
