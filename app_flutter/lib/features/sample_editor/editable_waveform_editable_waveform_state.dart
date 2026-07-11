part of 'editable_waveform.dart';

class _EditableWaveformState extends State<EditableWaveform> {
  _WaveHandle? drag;
  int? pointer;
  final activePointers = <int>{};
  Offset? pointerStart;
  int? sliceDragIndex;
  bool sliceMoved = false;

  double _slicePosition(Offset position, Size size) {
    final raw = (position.dx / size.width).clamp(0.0, 1.0);
    return ((raw - widget.start) / math.max(.001, widget.end - widget.start))
        .clamp(0.0, 1.0);
  }

  bool _begin(Offset position, Size size) {
    const top = 10.0;
    final inStart = widget.start * size.width;
    final outEnd = widget.end * size.width;
    final inEnd = (widget.start + (widget.end - widget.start) * widget.fadeIn) *
        size.width;
    final outStart =
        (widget.end - (widget.end - widget.start) * widget.fadeOut) *
            size.width;
    final points = <_WaveHandle, Offset>{};
    if (widget.trimToolActive) {
      points[_WaveHandle.trimStart] = Offset(inStart, size.height / 2);
      points[_WaveHandle.trimEnd] = Offset(outEnd, size.height / 2);
    }
    if (widget.fadeToolActive) {
      points.addAll({
        _WaveHandle.fadeIn: Offset(inEnd, top),
        _WaveHandle.fadeOut: Offset(outStart, top),
      });
    }
    if (points.isEmpty) {
      drag = null;
      return false;
    }
    final nearest = points.entries.reduce((a, b) =>
        (a.value - position).distance < (b.value - position).distance ? a : b);
    if ((nearest.value - position).distance > 24) {
      drag = null;
      return false;
    }
    drag = nearest.key;
    return true;
  }

  void _update(Offset position, Size size) {
    final value = (position.dx / size.width).clamp(0.0, 1.0);
    final span = math.max(.001, widget.end - widget.start);
    switch (drag) {
      case _WaveHandle.trimStart:
        widget.onTrimChanged(value.clamp(0.0, widget.end - .001), widget.end);
      case _WaveHandle.trimEnd:
        widget.onTrimChanged(
            widget.start, value.clamp(widget.start + .001, 1.0));
      case _WaveHandle.fadeIn:
        widget.onFadesChanged(
            ((value - widget.start) / span).clamp(0.0, 1.0), widget.fadeOut);
      case _WaveHandle.fadeOut:
        widget.onFadesChanged(
            widget.fadeIn, ((widget.end - value) / span).clamp(0.0, 1.0));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, box) => Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (!widget.trimToolActive &&
                  !widget.fadeToolActive &&
                  !widget.sliceToolActive) return;
              activePointers.add(event.pointer);
              if (activePointers.length > 1) {
                drag = null;
                pointer = null;
                return;
              }
              if (widget.sliceToolActive) {
                pointer = event.pointer;
                pointerStart = event.localPosition;
                widget.onInteractionChanged(true);
                final position =
                    _slicePosition(event.localPosition, box.biggest);
                var bestDistance = 22 /
                    math.max(1, box.maxWidth * (widget.end - widget.start));
                sliceDragIndex = null;
                for (var i = 0; i < widget.sliceMarkers.length; i++) {
                  final distance = (widget.sliceMarkers[i] - position).abs();
                  if (distance < bestDistance) {
                    bestDistance = distance;
                    sliceDragIndex = i;
                  }
                }
                sliceMoved = false;
              } else {
                if (!_begin(event.localPosition, box.biggest)) {
                  pointer = null;
                  pointerStart = null;
                  activePointers.remove(event.pointer);
                  return;
                }
                pointer = event.pointer;
                pointerStart = event.localPosition;
                widget.onInteractionChanged(true);
              }
            },
            onPointerMove: (event) {
              if (activePointers.length == 1 && event.pointer == pointer) {
                if (widget.sliceToolActive && sliceDragIndex != null) {
                  if ((event.localPosition -
                              (pointerStart ?? event.localPosition))
                          .distance >
                      5) {
                    sliceMoved = true;
                    widget.onSliceMove(sliceDragIndex!,
                        _slicePosition(event.localPosition, box.biggest));
                  }
                } else {
                  _update(event.localPosition, box.biggest);
                }
              }
            },
            onPointerUp: (event) {
              activePointers.remove(event.pointer);
              if (activePointers.isNotEmpty) return;
              final startPosition = pointerStart;
              if (widget.sliceToolActive && startPosition != null) {
                final position =
                    _slicePosition(event.localPosition, box.biggest);
                if (sliceDragIndex != null) {
                  if (sliceMoved)
                    widget.onSliceMoveEnd();
                  else
                    widget.onSliceToggle(widget.sliceMarkers[sliceDragIndex!]);
                } else {
                  widget.onSliceToggle(position);
                }
              }
              pointer = null;
              pointerStart = null;
              drag = null;
              sliceDragIndex = null;
              widget.onInteractionChanged(false);
              widget.onEditEnd();
            },
            onPointerCancel: (event) {
              activePointers.remove(event.pointer);
              if (activePointers.isNotEmpty) return;
              pointer = null;
              pointerStart = null;
              drag = null;
              widget.onInteractionChanged(false);
            },
            child: CustomPaint(
              painter: _WaveformPainter(
                  widget.peaks,
                  widget.start,
                  widget.end,
                  widget.fadeIn,
                  widget.fadeOut,
                  widget.fadeInCurve,
                  widget.fadeOutCurve,
                  widget.gain,
                  widget.reversed,
                  widget.trimToolActive,
                  widget.fadeToolActive,
                  widget.sliceToolActive,
                  widget.sliceMarkers,
                  widget.selectedSlice,
                  widget.playhead),
              child: const SizedBox.expand(),
            ),
          ));
}
