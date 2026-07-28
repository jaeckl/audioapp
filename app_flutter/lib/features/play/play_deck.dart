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

part 'play_deck_play_deck_state_set_surface_mode.dart';
part 'play_deck_play_deck_state_toggle_latch.dart';
part 'play_deck_play_deck_state_toggle_metronome.dart';
part 'play_deck_play_deck_state_set_metronome.dart';
part 'play_deck_play_deck_state_notify_performance.dart';
part 'play_deck_play_deck_state_on_octave_delta.dart';
part 'play_deck_play_deck_state_on_surface_mode_changed.dart';
part 'play_deck_play_deck_state_on_view_changed.dart';
part 'play_deck_play_deck_state_update_highlights.dart';
part 'play_deck_play_deck_state_build_chord_pitches.dart';
part 'play_deck_play_deck_state_build_context_area.dart';

const int _rootMidi = 60;
const _noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

/// Shared play surface: rail (Pads/Keys · Octave · Perform · Perf), mod strip,
/// and context panels — used in Play tab and piano roll editor.
class PlayDeck extends StatefulWidget {
  const PlayDeck({
    super.key,
    required this.bridge,
    this.enabled = true,
    this.showModStrip = true,
    this.showRail = true,
    this.initialSurfaceMode,
    this.initialOctaveOffset = 0,
    this.padPitchBase,
    this.onPerformanceChanged,
    this.onChromeChanged,
  });

  final EngineBridge bridge;
  final bool enabled;
  final bool showModStrip;

  /// When false, rail hosted elsewhere (e.g. piano-roll tool dock in landscape).
  final bool showRail;
  final PlaySurfaceMode? initialSurfaceMode;
  final int initialOctaveOffset;

  /// When set (drum tracks), pad 0 fires this MIDI note instead of C3 (48).
  final int? padPitchBase;
  final VoidCallback? onPerformanceChanged;

  /// Fired when rail-visible state changes (mode / view / octave).
  final VoidCallback? onChromeChanged;

  @override
  State<PlayDeck> createState() => PlayDeckState();
}
