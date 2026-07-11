import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../bridge/project_snapshot.dart';
import 'modulator_preview.dart';
import 'modulator_types.dart';

part 'modulation_grid_private_modulation_grid_state.dart';
part 'modulation_grid_private_grid_slot.dart';
part 'modulation_grid_private_grid_column.dart';
part 'modulation_grid_private_modulator_tile.dart';
part 'modulation_grid_private_modulator_tile_state.dart';
part 'modulation_grid_private_add_modulator_tile.dart';
part 'modulation_grid_private_curve_tile_painter.dart';

/// Fixed 3-row modulator grid; tiles are square and fill the column with padding.
class ModulationGrid extends StatefulWidget {
  const ModulationGrid({
    super.key,
    required this.lfos,
    required this.selectedLfoId,
    required this.maxLfos,
    required this.connectModeLfoId,
    required this.playheadBeat,
    required this.bpm,
    required this.playing,
    required this.onLfoTap,
    required this.onLfoLongPress,
    required this.onAddModulator,
    required this.onRemoveLfo,
    this.targetsPanelVisible = false,
    this.onShowTargets,
    this.onHideTargets,
  });

  static const rowCount = 3;
  static const outerPadding = 6.0;
  static const cellGap = 5.0;

  final List<LfoSnapshot> lfos;
  final int? selectedLfoId;
  final int maxLfos;
  final int? connectModeLfoId;
  final double playheadBeat;
  final int bpm;
  final bool playing;
  final ValueChanged<int> onLfoTap;
  final ValueChanged<int> onLfoLongPress;
  final Future<void> Function(int modulatorType) onAddModulator;
  final ValueChanged<int> onRemoveLfo;
  final bool targetsPanelVisible;
  final ValueChanged<int>? onShowTargets;
  final ValueChanged<int>? onHideTargets;

  @override
  State<ModulationGrid> createState() => _ModulationGridState();
}

/// A single column of tiles in the modulator grid.
/// Paints a small breakpoint curve preview for curve modulator tiles.
