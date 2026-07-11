part of 'modulation_grid.dart';

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
                widget.targetsPanelVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
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
        const PopupMenuItem<String>(
          value: 'remove',
          child: Row(
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
                  Icon(Icons.shuffle,
                      size: 16, color: accent.withValues(alpha: 0.7)),
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
                      final stepIdx = ((i / displayCount) * count)
                          .floor()
                          .clamp(0, steps.length - 1);
                      final val = (steps.isNotEmpty ? steps[stepIdx] : 0.5)
                          .clamp(0.0, 1.0);
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

    // Curve tiles show a mini breakpoint curve preview
    if (widget.lfo.modulatorType == ModulatorTypes.curve) {
      final positions = widget.lfo.curveBpPositions;
      final values = widget.lfo.curveBpValues;
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
              child: CustomPaint(
                painter: _CurveTilePainter(
                  positions: positions,
                  values: values,
                  accent: accent,
                ),
                size: Size.infinite,
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
