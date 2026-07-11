part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateBuildcanvas
    on AutomationEditorViewportState {
  Widget _buildCanvas() {
    return SizedBox(
      key: _canvasKey,
      width: _gridWidth,
      height: _valueAxisHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(_gridWidth, _valueAxisHeight),
            painter: AutomationCurveGridPainter(
              virtualLengthBeats: widget.virtualLengthBeats,
              clipLengthBeats: widget.clipLengthBeats,
              pixelsPerBeat: _pixelsPerBeat,
              gridStepBeats: widget.gridSettings.snapBeats,
              points: widget.points,
              selectedIndices: widget.selectedIndices,
              deleteMarkedIndices: widget.deleteMarkedIndices,
              insertHighlightStartBeat: _paintingShape
                  ? math.min(_shapeStartBeat!, _shapeEndBeat!)
                  : widget.insertHighlightStartBeat,
              insertHighlightEndBeat: _paintingShape
                  ? math.max(_shapeStartBeat!, _shapeEndBeat!)
                  : widget.insertHighlightEndBeat,
            ),
          ),
        ],
      ),
    );
  }
}
