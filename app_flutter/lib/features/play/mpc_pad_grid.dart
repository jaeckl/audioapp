import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'play_deck_theme.dart';
import 'play_scale.dart';

part 'mpc_pad_grid_mpc_pad_grid_state.dart';
part 'mpc_pad_grid_pad_cell.dart';
part 'mpc_pad_grid_pad_cell_state.dart';
part 'mpc_pad_grid_pad_drag.dart';

class MpcPadGrid extends StatefulWidget {
  const MpcPadGrid({
    super.key,
    required this.bridge,
    required this.bankOffset,
    this.pitchBase,
    this.highlightedPitches = const <int>{},
    this.chokeGroupByColumn = false,
    this.chokeGroupByRow = false,
    this.noteRepeatMs = 0,
    this.velocityCurve = VelocityCurve.linear,
    this.onModulationChanged,
    this.onPitchBendChanged,
    this.rowCount = 5,
  });

  final EngineBridge bridge;
  final int bankOffset;

  /// Drum tracks: GM anchor (e.g. 38 snare). Null → chromatic grid at C3 (48).
  final int? pitchBase;
  final Set<int> highlightedPitches;
  final bool chokeGroupByColumn;
  final bool chokeGroupByRow;
  final int noteRepeatMs;
  final VelocityCurve velocityCurve;
  final ValueChanged<double>? onModulationChanged;
  final ValueChanged<double>? onPitchBendChanged;
  final int rowCount;

  static const columns = 4;
  static const rows = 5;
  static const padCount = columns * rows;

  @override
  State<MpcPadGrid> createState() => _MpcPadGridState();
}
