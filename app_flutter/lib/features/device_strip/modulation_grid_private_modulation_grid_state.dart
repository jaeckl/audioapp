part of 'modulation_grid.dart';

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
              title:
                  const Text('Envelope', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'ADSR · ASR · ADR · AHDSR',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ModulatorTypes.envelope),
            ),
            ListTile(
              leading: const Icon(Icons.shuffle, color: Color(0xFFE8A54B)),
              title: const Text('Random Generator',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Sample & hold with smoothing',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () =>
                  Navigator.pop(context, ModulatorTypes.randomGenerator),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view, color: Color(0xFF4BC8E8)),
              title: const Text('Sequencer',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Step-sequenced modulation pattern',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ModulatorTypes.sequencer),
            ),
            ListTile(
              leading: const Icon(Icons.timeline, color: Color(0xFFE8A54B)),
              title: const Text('Curve', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'User-drawn breakpoint curve editor',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ModulatorTypes.curve),
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
              final cellSize = math.max(
                  0.0,
                  (contentH -
                          ModulationGrid.cellGap *
                              (ModulationGrid.rowCount - 1)) /
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
                        const SizedBox(width: ModulationGrid.cellGap),
                      _GridColumn(
                        slots: gridColumns[colIdx],
                        cellSize: cellSize,
                        isNarrow: gridColumns[colIdx].every((s) => s.isAdd),
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
