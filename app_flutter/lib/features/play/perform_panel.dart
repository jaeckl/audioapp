import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'play_deck_theme.dart';

part 'perform_panel_perform_panel_state.dart';
part 'perform_panel_section_title.dart';
part 'perform_panel_pill.dart';
part 'perform_panel_slider_row.dart';
part 'perform_panel_key_row.dart';

/// Autochord + arpeggiator view. Plays live via the bridge while held.
class PerformPanel extends StatefulWidget {
  const PerformPanel({
    super.key,
    required this.bridge,
    required this.scaleId,
    required this.rootMidi,
    required this.chord,
    required this.arp,
    required this.octaveSpan,
    required this.rateMs,
    required this.highlightedRoot,
    required this.onChordChanged,
    required this.onArpChanged,
    required this.onSpanChanged,
    required this.onRateChanged,
    required this.onKeyDown,
    required this.onKeyUp,
  });

  final EngineBridge bridge;
  final String scaleId;
  final int rootMidi;
  final ChordQuality chord;
  final ArpMode arp;
  final int octaveSpan;
  final int rateMs;
  final int highlightedRoot;
  final ValueChanged<ChordQuality> onChordChanged;
  final ValueChanged<ArpMode> onArpChanged;
  final ValueChanged<int> onSpanChanged;
  final ValueChanged<int> onRateChanged;
  final ValueChanged<int> onKeyDown;
  final VoidCallback onKeyUp;

  @override
  State<PerformPanel> createState() => _PerformPanelState();
}
