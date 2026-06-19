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
  });

  static const rowCount = 3;
  static const outerPadding = 6.0;
  static const cellGap = 4.0;

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
              title: const Text('ADSR', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Attack · decay · sustain · release',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ModulatorTypes.adsr),
            ),
            ListTile(
              leading: const Icon(Icons.timeline, color: Color(0xFFE8A54B)),
              title: const Text('ADR', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Attack · decay · release (no sustain)',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ModulatorTypes.adr),
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
    final slots = <_GridSlot>[
      for (final lfo in widget.lfos) _GridSlot.modulator(lfo),
    ];
    if (slots.length < widget.maxLfos) {
      slots.add(const _GridSlot.add());
    }
    return slots;
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
              final contentW =
                  constraints.maxWidth - ModulationGrid.outerPadding * 2;
              final contentH =
                  constraints.maxHeight - ModulationGrid.outerPadding;
              final cellFromHeight = (contentH -
                      ModulationGrid.cellGap * (ModulationGrid.rowCount - 1)) /
                  ModulationGrid.rowCount;
              // Single column: square tiles fill column width, capped to fit 3 rows.
              final cellSize = math.max(
                0.0,
                math.min(contentW, cellFromHeight),
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  ModulationGrid.outerPadding,
                  0,
                  ModulationGrid.outerPadding,
                  ModulationGrid.outerPadding,
                ),
                child: ListView.separated(
                  physics: slots.length > ModulationGrid.rowCount
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: slots.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: ModulationGrid.cellGap),
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    if (slot.isAdd) {
                      return _AddModulatorTile(
                        onPressed: _showAddMenu,
                        size: cellSize,
                      );
                    }
                    final lfo = slot.lfo!;
                    return _ModulatorTile(
                      lfo: lfo,
                      size: cellSize,
                      playheadBeat: playhead,
                      bpm: widget.bpm,
                      elapsedSeconds: _elapsedSeconds,
                      isSelected: lfo.id == widget.selectedLfoId,
                      isConnectMode: lfo.id == widget.connectModeLfoId,
                      onTap: () => widget.onLfoTap(lfo.id),
                      onLongPress: () => widget.onLfoLongPress(lfo.id),
                      onRemove: () => widget.onRemoveLfo(lfo.id),
                    );
                  },
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

class _ModulatorTile extends StatelessWidget {
  const _ModulatorTile({
    required this.lfo,
    required this.size,
    required this.playheadBeat,
    required this.bpm,
    required this.elapsedSeconds,
    required this.isSelected,
    required this.isConnectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
  });

  final LfoSnapshot lfo;
  final double size;
  final double playheadBeat;
  final int bpm;
  final double elapsedSeconds;
  final bool isSelected;
  final bool isConnectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE8A54B);
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ModulatorPreview(
              mod: lfo,
              playheadBeat: playheadBeat,
              bpm: bpm,
              elapsedSeconds: elapsedSeconds,
              accent: accent,
              isSelected: isSelected,
              isConnectMode: isConnectMode,
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A35),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.close, size: 9, color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddModulatorTile extends StatelessWidget {
  const _AddModulatorTile({
    required this.onPressed,
    required this.size,
  });

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: const Color(0xFF181821),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
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
