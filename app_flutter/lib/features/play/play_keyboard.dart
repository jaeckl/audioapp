import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'play_deck_layout.dart';
import 'play_deck_theme.dart';
import 'play_scale.dart';

part 'play_keyboard_play_keyboard_state.dart';
part 'play_keyboard_key_drag.dart';
part 'play_keyboard_scale_key_grid.dart';
part 'play_keyboard_chromatic_piano.dart';
part 'play_keyboard_key_cell.dart';

class PlayKeyboard extends StatefulWidget {
  const PlayKeyboard({
    super.key,
    required this.bridge,
    required this.scale,
    required this.inKeyOnly,
    required this.octaveOffset,
    required this.rowCount,
    this.scrollOffset = 0,
    this.highlightedPitches = const <int>{},
    this.velocityCurve = VelocityCurve.linear,
    this.onModulationChanged,
    this.onPitchBendChanged,
  });

  final EngineBridge bridge;
  final PlayScale scale;
  final bool inKeyOnly;
  final int octaveOffset;
  final int rowCount;
  final int scrollOffset;
  final Set<int> highlightedPitches;
  final VelocityCurve velocityCurve;
  final ValueChanged<double>? onModulationChanged;
  final ValueChanged<double>? onPitchBendChanged;

  @override
  State<PlayKeyboard> createState() => _PlayKeyboardState();
}
