part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateBuildnotecanvasviewport
    on PianoRollViewportState {
  Widget _buildNoteCanvasViewport() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ScrollConfiguration(
                behavior: const _PianoRollScrollBehavior(),
                child: SingleChildScrollView(
                  controller: _vertical,
                  physics: _scrollPhysics,
                  child: SingleChildScrollView(
                    controller: _horizontal,
                    scrollDirection: Axis.horizontal,
                    physics: _scrollPhysics,
                    child: SizedBox(
                      width: _gridWidth,
                      height: _gridHeight,
                      child: Listener(
                        onPointerDown: _onCanvasPointerDown,
                        onPointerMove: _onCanvasPointerMove,
                        onPointerUp: _onCanvasPointerUp,
                        onPointerCancel: _onCanvasPointerUp,
                        behavior: HitTestBehavior.opaque,
                        child: _buildNoteCanvas(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.onHarmonyInsertTap != null)
              _buildHarmonyInsertFab(viewportHeight: constraints.maxHeight),
          ],
        );
      },
    );
  }

  /// Vertically locked to viewport center; horizontally tracks empty beat.
  Widget _buildHarmonyInsertFab({required double viewportHeight}) {
    const size = 48.0;
    final beat = HarmonicNoteOps.nextEmptyStart(
      widget.notes,
      slots: widget.chordSlots.isEmpty ? null : widget.chordSlots,
    );
    final top = ((viewportHeight - size) / 2).clamp(0.0, viewportHeight);
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      height: size,
      child: ListenableBuilder(
        listenable: _horizontal,
        builder: (context, _) {
          final scroll =
              _horizontal.hasClients ? _horizontal.offset : 0.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: beat * _pixelsPerBeat - scroll,
                top: 0,
                child: HarmonicRollPlusButton(
                  tooltip: widget.harmonyInsertTooltip,
                  onTap: widget.onHarmonyInsertTap!,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
