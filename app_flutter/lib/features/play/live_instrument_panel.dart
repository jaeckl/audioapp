import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../../app/record_write_mode.dart';
import 'play_deck.dart';
import 'play_deck_layout.dart';

part 'live_instrument_panel_live_instrument_panel_state.dart';
part 'live_instrument_panel_capture_strip.dart';
part 'live_instrument_panel_record_mode_selector.dart';
part 'live_instrument_panel_simple_text_button.dart';

/// On-screen piano / pads panel shown below the arrangement timeline.
class LiveInstrumentPanel extends StatefulWidget {
  const LiveInstrumentPanel({
    super.key,
    required this.bridge,
    required this.snapshot,
    required this.onRecordArmed,
    required this.recordWriteMode,
    required this.onRecordWriteModeChanged,
  });

  final EngineBridge bridge;
  final ProjectSnapshot snapshot;
  final Future<void> Function(bool armed) onRecordArmed;
  final RecordWriteMode recordWriteMode;
  final ValueChanged<RecordWriteMode> onRecordWriteModeChanged;

  @override
  State<LiveInstrumentPanel> createState() => _LiveInstrumentPanelState();
}
