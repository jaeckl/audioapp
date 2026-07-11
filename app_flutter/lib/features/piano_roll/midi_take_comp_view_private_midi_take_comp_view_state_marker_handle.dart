part of 'midi_take_comp_view.dart';

extension _MidiTakeCompViewStateMarkerhandle on _MidiTakeCompViewState {
  Widget _markerHandle({
    required int index,
    required MidiClipTakeRegionSnapshot region,
    required double scroll,
  }) {
    final beat =
        index == _dragMarkerIndex ? _dragMarkerBeat! : region.startBeat;
    final viewportX = _labelRailWidth + beat * _pixelsPerBeat - scroll;
    if (viewportX < _labelRailWidth - 0.5) return const SizedBox.shrink();
    final selected = widget.selectedMarker == index;
    final interactive = _canSelectMarker || _canDragMarker;
    return Positioned(
      left: viewportX - ArrangementLoopRegionTheme.hitWidth / 2,
      top: (_rulerHeight - ArrangementLoopRegionTheme.pillSize) / 2,
      bottom: 0,
      width: ArrangementLoopRegionTheme.hitWidth,
      child: IgnorePointer(
        ignoring: !interactive,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _canSelectMarker ? () => widget.onMarkerSelected(index) : null,
          onHorizontalDragStart: _canDragMarker
              ? (_) {
                  setState(() {
                    _dragMarkerIndex = index;
                    _dragMarkerBeat = region.startBeat;
                  });
                  widget.onMarkerSelected(index);
                }
              : null,
          onHorizontalDragUpdate: _canDragMarker
              ? (details) {
                  final next = ((_dragMarkerBeat ?? region.startBeat) +
                          details.delta.dx / _pixelsPerBeat)
                      .clamp(0.0, widget.clipLengthBeats);
                  setState(() => _dragMarkerBeat = next);
                  widget.onMarkerMove(index, next);
                }
              : null,
          onHorizontalDragEnd: _canDragMarker
              ? (_) {
                  final next = _dragMarkerBeat ?? region.startBeat;
                  setState(() {
                    _dragMarkerIndex = null;
                    _dragMarkerBeat = null;
                  });
                  widget.onMarkerMoveEnd(index, next);
                }
              : null,
          onHorizontalDragCancel: _canDragMarker
              ? () => setState(() {
                    _dragMarkerIndex = null;
                    _dragMarkerBeat = null;
                  })
              : null,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: ArrangementLoopRegionTheme.pillSize / 2,
                bottom: 0,
                width: 2,
                child: ColoredBox(
                  color: selected
                      ? Colors.white
                      : ArrangementLoopRegionTheme.color,
                ),
              ),
              const ArrangementLoopRegionPill(),
            ],
          ),
        ),
      ),
    );
  }
}
