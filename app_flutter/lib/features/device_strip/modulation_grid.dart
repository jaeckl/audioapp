import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../bridge/project_snapshot.dart';
import 'modulator_preview.dart';
import 'modulator_types.dart';

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

class _ModulationGridState extends State<ModulationGrid>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _elapsedSeconds = 0;
  Duration? _lastTick;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick != null) {
      _elapsedSeconds += (elapsed - _lastTick!).inMicroseconds / 1e6;
    }
    _lastTick = elapsed;
    if (mounted) setState(() {});
  }

  Future<void> _showAddMenu() async {
    final type = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.waves, color: Color(0xFFE8A54B)),
              title: const Text('LFO', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Periodic modulation',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ModulatorTypes.lfo),
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq, color: Color(0xFFE8A54B)),
              title: const Text('Envelope', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'ADSR · ASR · ADR · AHDSR',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ModulatorTypes.envelope),
            ),
            ListTile(
              leading: const Icon(Icons.shuffle, color: Color(0xFFE8A54B)),
              title: const Text('Random Generator', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Sample & hold with smoothing',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ModulatorTypes.randomGenerator),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view, color: Color(0xFF4BC8E8)),
              title: const Text('Sequencer', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Step-sequenced modulation pattern',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ModulatorTypes.sequencer),
            ),
          ],
        ),
      ),
    );
    if (type != null) {
      await widget.onAddModulator(type);
    }
  }

  List<_GridSlot> _slots() {
    final result = <_GridSlot>[
      for (final lfo in widget.lfos) _GridSlot.modulator(lfo),
    ];
    if (result.length >= widget.maxLfos) return result;
    // Pad to fill the current column so every column is complete.
    final remainder = result.length % ModulationGrid.rowCount;
    final fillCount = remainder == 0
        ? ModulationGrid.rowCount
        : ModulationGrid.rowCount - remainder;
    final addCount = math.min(fillCount, widget.maxLfos - result.length);
    for (var i = 0; i < addCount; i++) {
      result.add(const _GridSlot.add());
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFFE8A54B);
    final playhead = widget.playheadBeat;
    final slots = _slots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ModulationGrid.outerPadding,
            4,
            ModulationGrid.outerPadding,
            ModulationGrid.cellGap,
          ),
          child: Text(
            'MODULATORS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentH =
                  constraints.maxHeight - ModulationGrid.outerPadding;
              // Square cell sized to fit exactly 3 rows
              final cellSize = math.max(0.0,
                  (contentH - ModulationGrid.cellGap * (ModulationGrid.rowCount - 1)) /
                      ModulationGrid.rowCount);

              // Partition slots into columns (column-major order)
              final gridColumns = <List<_GridSlot>>[];
              for (var i = 0; i < slots.length; i += ModulationGrid.rowCount) {
                gridColumns.add(
                  slots.sublist(
                      i, math.min(i + ModulationGrid.rowCount, slots.length)),
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  ModulationGrid.outerPadding,
                  0,
                  ModulationGrid.outerPadding,
                  ModulationGrid.outerPadding,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var colIdx = 0;
                        colIdx < gridColumns.length;
                        colIdx++) ...[
                      if (colIdx > 0)
                        SizedBox(width: ModulationGrid.cellGap),
                      _GridColumn(
                        slots: gridColumns[colIdx],
                        cellSize: cellSize,
                        isNarrow:
                            gridColumns[colIdx].every((s) => s.isAdd),
                        selectedLfoId: widget.selectedLfoId,
                        connectModeLfoId: widget.connectModeLfoId,
                        playheadBeat: playhead,
                        bpm: widget.bpm,
                        elapsedSeconds: _elapsedSeconds,
                        targetsPanelVisible: widget.targetsPanelVisible,
                        onLfoTap: widget.onLfoTap,
                        onLfoLongPress: widget.onLfoLongPress,
                        onRemoveLfo: widget.onRemoveLfo,
                        onShowTargets: widget.onShowTargets,
                        onHideTargets: widget.onHideTargets,
                        onShowAddMenu: _showAddMenu,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GridSlot {
  const _GridSlot.modulator(this.lfo) : isAdd = false;
  const _GridSlot.add() : lfo = null, isAdd = true;

  final LfoSnapshot? lfo;
  final bool isAdd;
}

/// A single column of tiles in the modulator grid.
class _GridColumn extends StatelessWidget {
  const _GridColumn({
    required this.slots,
    required this.cellSize,
    required this.isNarrow,
    required this.selectedLfoId,
    required this.connectModeLfoId,
    required this.playheadBeat,
    required this.bpm,
    required this.elapsedSeconds,
    required this.targetsPanelVisible,
    required this.onLfoTap,
    required this.onLfoLongPress,
    required this.onRemoveLfo,
    required this.onShowTargets,
    required this.onHideTargets,
    required this.onShowAddMenu,
  });

  final List<_GridSlot> slots;
  final double cellSize;
  final bool isNarrow;
  final int? selectedLfoId;
  final int? connectModeLfoId;
  final double playheadBeat;
  final int bpm;
  final double elapsedSeconds;
  final bool targetsPanelVisible;
  final ValueChanged<int> onLfoTap;
  final ValueChanged<int> onLfoLongPress;
  final ValueChanged<int> onRemoveLfo;
  final ValueChanged<int>? onShowTargets;
  final ValueChanged<int>? onHideTargets;
  final VoidCallback onShowAddMenu;

  @override
  Widget build(BuildContext context) {
    final tileW = isNarrow ? cellSize / 3 : cellSize;
    final tileH = cellSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) SizedBox(height: ModulationGrid.cellGap),
          _buildTile(slots[i], tileW, tileH),
        ],
      ],
    );
  }

  Widget _buildTile(_GridSlot slot, double tileW, double tileH) {
    if (slot.isAdd) {
      return _AddModulatorTile(
        onPressed: onShowAddMenu,
        width: tileW,
        height: tileH,
      );
    }
    final lfo = slot.lfo!;
    return _ModulatorTile(
      lfo: lfo,
      size: tileW,
      playheadBeat: playheadBeat,
      bpm: bpm,
      elapsedSeconds: elapsedSeconds,
      isSelected: lfo.id == selectedLfoId,
      isConnectMode: lfo.id == connectModeLfoId,
      targetsPanelVisible: targetsPanelVisible,
      onTap: () => onLfoTap(lfo.id),
      onLongPress: () => onLfoLongPress(lfo.id),
      onRemove: () => onRemoveLfo(lfo.id),
      onShowTargets: onShowTargets != null ? () => onShowTargets!(lfo.id) : null,
      onHideTargets: onHideTargets != null ? () => onHideTargets!(lfo.id) : null,
    );
  }
}

class _ModulatorTile extends StatefulWidget {
  const _ModulatorTile({
    required this.lfo,
    required this.size,
    required this.playheadBeat,
    required this.bpm,
    required this.elapsedSeconds,
    required this.isSelected,
    required this.isConnectMode,
    required this.targetsPanelVisible,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
    this.onShowTargets,
    this.onHideTargets,
  });

  final LfoSnapshot lfo;
  final double size;
  final double playheadBeat;
  final int bpm;
  final double elapsedSeconds;
  final bool isSelected;
  final bool isConnectMode;
  final bool targetsPanelVisible;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;
  final VoidCallback? onShowTargets;
  final VoidCallback? onHideTargets;

  @override
  State<_ModulatorTile> createState() => _ModulatorTileState();
}

class _ModulatorTileState extends State<_ModulatorTile> {
  void _onDoubleTap() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height + 1,
      ),
      color: const Color(0xFF1A1A24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      items: [
        PopupMenuItem<String>(
          value: 'targets',
          child: Row(
            children: [
              Icon(
                widget.targetsPanelVisible ? Icons.visibility : Icons.visibility_off,
                size: 16,
                color: widget.targetsPanelVisible
                    ? const Color(0xFFE8A54B)
                    : Colors.white54,
              ),
              const SizedBox(width: 8),
              Text(
                widget.targetsPanelVisible ? 'Hide targets' : 'Show targets',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'remove',
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Color(0xFFE8554B)),
              SizedBox(width: 8),
              Text(
                'Remove',
                style: TextStyle(color: Color(0xFFE8554B), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'targets') {
        if (widget.targetsPanelVisible) {
          widget.onHideTargets?.call();
        } else {
          widget.onShowTargets?.call();
        }
      } else if (value == 'remove') {
        widget.onRemove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE8A54B);

    // Random generator tiles show a static centered label, not a curve preview.
    if (widget.lfo.modulatorType == ModulatorTypes.randomGenerator) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: GestureDetector(
          onTap: widget.onTap,
          onDoubleTap: _onDoubleTap,
          onLongPress: widget.onLongPress,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF101018),
              borderRadius: BorderRadius.circular(ModulatorPreview.tileRadius),
              border: widget.isSelected || widget.isConnectMode
                  ? Border.all(
                      color: widget.isConnectMode
                          ? accent
                          : accent.withValues(alpha: 0.75),
                      width: widget.isConnectMode ? 1.5 : 1.0,
                    )
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shuffle, size: 16, color: accent.withValues(alpha: 0.7)),
                  const SizedBox(height: 4),
                  Text(
                    '${ModulatorTypes.labelFor(widget.lfo.modulatorType)} ${widget.lfo.id}',
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.85),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Sequencer tiles show a mini step bar preview.
    if (widget.lfo.modulatorType == ModulatorTypes.sequencer) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: GestureDetector(
          onTap: widget.onTap,
          onDoubleTap: _onDoubleTap,
          onLongPress: widget.onLongPress,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF101018),
              borderRadius: BorderRadius.circular(ModulatorPreview.tileRadius),
              border: widget.isSelected || widget.isConnectMode
                  ? Border.all(
                      color: widget.isConnectMode
                          ? accent
                          : accent.withValues(alpha: 0.75),
                      width: widget.isConnectMode ? 1.5 : 1.0,
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final steps = widget.lfo.stepValues;
                  final count = widget.lfo.sequencerSteps.clamp(1, 32);
                  // Max 12 bars in preview to keep it readable in a tiny grid tile
                  final displayCount = count > 12 ? 12 : count;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(displayCount, (i) {
                      // Map index correctly to sample from the full step array
                      final stepIdx = ((i / displayCount) * count).floor().clamp(0, steps.length - 1);
                      final val = (steps.isNotEmpty ? steps[stepIdx] : 0.5).clamp(0.0, 1.0);
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: val,
                            widthFactor: 1.0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(0.5),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: _onDoubleTap,
        onLongPress: widget.onLongPress,
        child: ModulatorPreview(
          mod: widget.lfo,
          playheadBeat: widget.playheadBeat,
          bpm: widget.bpm,
          elapsedSeconds: widget.elapsedSeconds,
          accent: accent,
          isSelected: widget.isSelected,
          isConnectMode: widget.isConnectMode,
          innerPadding: 2.0,
        ),
      ),
    );
  }
}

class _AddModulatorTile extends StatelessWidget {
  const _AddModulatorTile({
    required this.onPressed,
    required this.width,
    required this.height,
  });

  final VoidCallback onPressed;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: const Color(0xFF181821),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(Icons.add, size: 18, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}
