part of 'midi_take_comp_view.dart';

extension _MidiTakeCompViewStatePlayheadwidgets on _MidiTakeCompViewState {
  List<Widget> _playheadWidgets(double beat, double scroll) {
    final viewportX = _labelRailWidth + beat * _pixelsPerBeat - scroll;
    if (viewportX < _labelRailWidth - 0.5) return const [];
    return [
      Positioned(
        left: viewportX - editorVirtualPlayheadLineWidth / 2,
        top: _rulerHeight / 2,
        bottom: 0,
        width: editorVirtualPlayheadLineWidth,
        child: const IgnorePointer(
          child: ColoredBox(color: EditorVirtualPlayheadTheme.color),
        ),
      ),
      Positioned(
        left: viewportX - EditorVirtualPlayheadTheme.hitWidth / 2,
        top: 0,
        width: EditorVirtualPlayheadTheme.hitWidth,
        height: EditorVirtualPlayheadTheme.pillSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => setState(() => _dragBeat = beat),
          onHorizontalDragUpdate: (details) {
            final next =
                ((_dragBeat ?? beat) + details.delta.dx / _pixelsPerBeat)
                    .clamp(0.0, widget.clipLengthBeats);
            setState(() => _dragBeat = next);
            widget.onPlayheadSeek(next);
          },
          onHorizontalDragEnd: (_) => setState(() => _dragBeat = null),
          onHorizontalDragCancel: () => setState(() => _dragBeat = null),
          child: const EditorVirtualPlayheadPill(),
        ),
      ),
    ];
  }
}
