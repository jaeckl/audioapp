import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'mod_strip.dart';
import 'mpc_pad_grid.dart';
import 'octave_panel.dart';
import 'perform_panel.dart';
import 'performance_panel.dart';
import 'play_deck_layout.dart';
import 'play_deck_rail.dart';
import 'play_deck_theme.dart';
import 'play_keyboard.dart';
import 'play_scale.dart';
import 'scale_builder_panel.dart';

part 'play_deck_play_deck_state.dart';

/// Shared play surface: rail (Pads/Keys · Octave · Perform · Perf), mod strip,
/// and context panels — used in Play tab and piano roll editor.
class PlayDeck extends StatefulWidget {
  const PlayDeck({
    super.key,
    required this.bridge,
    this.enabled = true,
    this.showModStrip = true,
    this.initialSurfaceMode,
    this.initialOctaveOffset = 0,
    this.padPitchBase,
    this.onPerformanceChanged,
  });

  final EngineBridge bridge;
  final bool enabled;
  final bool showModStrip;
  final PlaySurfaceMode? initialSurfaceMode;
  final int initialOctaveOffset;

  /// When set (drum tracks), pad 0 fires this MIDI note instead of C3 (48).
  final int? padPitchBase;
  final VoidCallback? onPerformanceChanged;

  @override
  State<PlayDeck> createState() => PlayDeckState();
}
