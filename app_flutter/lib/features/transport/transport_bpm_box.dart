import 'package:flutter/material.dart';

import 'transport_bar_theme.dart';

part 'transport_bpm_box_private_transport_bpm_box_state.dart';

/// Compact BPM readout — drag the number up/down to change tempo.
class TransportBpmBox extends StatefulWidget {
  const TransportBpmBox({
    super.key,
    required this.bpm,
    this.enabled = true,
    this.onChanged,
  });

  static const int minBpm = 40;
  static const int maxBpm = 300;
  static const double dragPixelsPerStep = 10;

  final int bpm;
  final bool enabled;
  final ValueChanged<int>? onChanged;

  @override
  State<TransportBpmBox> createState() => _TransportBpmBoxState();
}
