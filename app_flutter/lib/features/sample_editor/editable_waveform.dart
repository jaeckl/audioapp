import 'dart:math' as math;
import 'package:flutter/material.dart';

enum _WaveHandle {
  trimStart,
  trimEnd,
  fadeIn,
  fadeOut,
  fadeInCurveA,
  fadeInCurveB,
  fadeOutCurveA,
  fadeOutCurveB
}

class EditableWaveform extends StatefulWidget {
  const EditableWaveform(
      {super.key,
      required this.peaks,
      required this.start,
      required this.end,
      required this.fadeIn,
      required this.fadeOut,
      required this.fadeInCurve,
      required this.fadeOutCurve,
      required this.gain,
      required this.reversed,
      required this.trimToolActive,
      required this.fadeToolActive,
      required this.sliceToolActive,
      required this.sliceMarkers,
      required this.onSliceToggle,
      required this.selectedSlice,
      required this.onSliceMove,
      required this.onSliceMoveEnd,
      required this.onSliceAudition,
      required this.onTrimChanged,
      required this.onFadesChanged,
      required this.onCurvesChanged,
      required this.onInteractionChanged,
      required this.onEditEnd,
      this.playhead = 0});
  final List<double> peaks;
  final double start,
      end,
      fadeIn,
      fadeOut,
      fadeInCurve,
      fadeOutCurve,
      gain,
      playhead;
  final bool reversed;
  final bool trimToolActive, fadeToolActive;
  final bool sliceToolActive;
  final List<double> sliceMarkers;
  final ValueChanged<double> onSliceToggle;
  final int? selectedSlice;
  final void Function(int, double) onSliceMove;
  final VoidCallback onSliceMoveEnd;
  final ValueChanged<double> onSliceAudition;
  final void Function(double start, double end) onTrimChanged;
  final void Function(double fadeIn, double fadeOut) onFadesChanged;
  final void Function(double fadeInCurve, double fadeOutCurve) onCurvesChanged;
  final ValueChanged<bool> onInteractionChanged;
  final VoidCallback onEditEnd;
  @override
  State<EditableWaveform> createState() => _EditableWaveformState();
}

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

  void _begin(Offset position, Size size) {
    final top = 10.0, bottom = size.height - 10.0;
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
        _WaveHandle.fadeInCurveA: Offset(inStart + (inEnd - inStart) * .35,
            bottom - (bottom - top) * widget.fadeInCurve),
        _WaveHandle.fadeInCurveB: Offset(inStart + (inEnd - inStart) * .65,
            top + (bottom - top) * widget.fadeInCurve),
        _WaveHandle.fadeOutCurveA: Offset(outStart + (outEnd - outStart) * .35,
            top + (bottom - top) * widget.fadeOutCurve),
        _WaveHandle.fadeOutCurveB: Offset(outStart + (outEnd - outStart) * .65,
            bottom - (bottom - top) * widget.fadeOutCurve),
      });
    }
    if (points.isEmpty) {
      drag = null;
      return;
    }
    drag = points.entries
        .reduce((a, b) =>
            (a.value - position).distance < (b.value - position).distance
                ? a
                : b)
        .key;
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
      case _WaveHandle.fadeInCurveA:
      case _WaveHandle.fadeOutCurveB:
        final curve =
            ((size.height - 10 - position.dy) / math.max(1, size.height - 20))
                .clamp(0.0, 1.0);
        if (drag == _WaveHandle.fadeInCurveA)
          widget.onCurvesChanged(curve, widget.fadeOutCurve);
        else
          widget.onCurvesChanged(widget.fadeInCurve, curve);
      case _WaveHandle.fadeInCurveB:
      case _WaveHandle.fadeOutCurveA:
        final curve = ((position.dy - 10) / math.max(1, size.height - 20))
            .clamp(0.0, 1.0);
        if (drag == _WaveHandle.fadeInCurveB)
          widget.onCurvesChanged(curve, widget.fadeOutCurve);
        else
          widget.onCurvesChanged(widget.fadeInCurve, curve);
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
              pointer = event.pointer;
              pointerStart = event.localPosition;
              widget.onInteractionChanged(true);
              if (widget.sliceToolActive) {
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
                _begin(event.localPosition, box.biggest);
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

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(
      this.peaks,
      this.start,
      this.end,
      this.fadeIn,
      this.fadeOut,
      this.fadeInCurve,
      this.fadeOutCurve,
      this.gain,
      this.reversed,
      this.trimToolActive,
      this.fadeToolActive,
      this.sliceToolActive,
      this.sliceMarkers,
      this.selectedSlice,
      this.playhead);
  final List<double> peaks;
  final double start,
      end,
      fadeIn,
      fadeOut,
      fadeInCurve,
      fadeOutCurve,
      gain,
      playhead;
  final bool reversed;
  final bool trimToolActive, fadeToolActive;
  final bool sliceToolActive;
  final List<double> sliceMarkers;
  final int? selectedSlice;

  double _rawPeakAt(double position) {
    if (peaks.isEmpty) return 0;
    final source = position.clamp(0.0, 1.0) * (peaks.length - 1);
    final lo = source.floor();
    final hi = math.min(peaks.length - 1, lo + 1);
    final t = source - lo;
    final smooth = t * t * (3 - 2 * t);
    return (peaks[lo] + (peaks[hi] - peaks[lo]) * smooth).abs().clamp(0.0, 1.0);
  }

  double _cubic(double t, double curve) {
    final value = t.clamp(0.0, 1.0);
    final inv = 1.0 - value;
    return 3 * inv * inv * value * curve +
        3 * inv * value * value * (1 - curve) +
        value * value * value;
  }

  double _peakAt(double position) {
    if (position < start || position > end || end <= start) {
      return _rawPeakAt(position);
    }
    final progress = ((position - start) / (end - start)).clamp(0.0, 1.0);
    final sourcePosition = reversed ? end - progress * (end - start) : position;
    var envelope = 1.0;
    if (fadeIn > 0) envelope *= _cubic(progress / fadeIn, fadeInCurve);
    if (fadeOut > 0) envelope *= _cubic((1 - progress) / fadeOut, fadeOutCurve);
    return (_rawPeakAt(sourcePosition) * gain * envelope).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    final shape = Path();
    final samples = math.max(peaks.length, size.width.ceil()).clamp(128, 4096);
    for (var i = 0; i <= samples; i++) {
      final p = i / samples;
      final x = p * size.width;
      final amp = _peakAt(p) * center * .82 + .6;
      if (i == 0) {
        shape.moveTo(x, center - amp);
      } else {
        shape.lineTo(x, center - amp);
      }
    }
    for (var i = samples; i >= 0; i--) {
      final p = i / samples;
      shape.lineTo(p * size.width, center + (_peakAt(p) * center * .82 + .6));
    }
    shape.close();
    canvas.drawPath(
        shape,
        Paint()
          ..color = const Color(0xff58cfc4).withValues(alpha: .72)
          ..isAntiAlias = true);
    canvas.drawPath(
        shape,
        Paint()
          ..color = const Color(0xffa1fff5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..isAntiAlias = true);

    final selected =
        Rect.fromLTRB(size.width * start, 0, size.width * end, size.height);
    final dim = Paint()..color = const Color(0xbb08080d);
    canvas.drawRect(Rect.fromLTRB(0, 0, selected.left, size.height), dim);
    canvas.drawRect(
        Rect.fromLTRB(selected.right, 0, size.width, size.height), dim);
    final curve = Paint()
      ..color = const Color(0xffb5a7ff)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final inX = selected.left + selected.width * fadeIn;
    final outX = selected.right - selected.width * fadeOut;
    const top = 10.0;
    final bottom = size.height - 10.0;
    final inA = Offset(selected.left + (inX - selected.left) * .35,
        bottom - (bottom - top) * fadeInCurve);
    final inB = Offset(selected.left + (inX - selected.left) * .65,
        top + (bottom - top) * fadeInCurve);
    final outA = Offset(outX + (selected.right - outX) * .35,
        top + (bottom - top) * fadeOutCurve);
    final outB = Offset(outX + (selected.right - outX) * .65,
        bottom - (bottom - top) * fadeOutCurve);
    if (fadeIn > 0)
      canvas.drawPath(
          Path()
            ..moveTo(selected.left, bottom)
            ..cubicTo(inA.dx, inA.dy, inB.dx, inB.dy, inX, top),
          curve);
    if (fadeOut > 0)
      canvas.drawPath(
          Path()
            ..moveTo(outX, top)
            ..cubicTo(
                outA.dx, outA.dy, outB.dx, outB.dy, selected.right, bottom),
          curve);
    final handle = Paint()..color = const Color(0xffb5a7ff);
    final guides = Paint()
      ..color = const Color(0x66b5a7ff)
      ..strokeWidth = 2;
    if (fadeToolActive && fadeIn > 0) {
      canvas.drawLine(Offset(selected.left, bottom), inA, guides);
      canvas.drawLine(Offset(inX, top), inB, guides);
      canvas.drawCircle(
          inA,
          9,
          handle
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      canvas.drawCircle(inB, 9, handle);
    }
    if (fadeToolActive && fadeOut > 0) {
      canvas.drawLine(Offset(outX, top), outA, guides);
      canvas.drawLine(Offset(selected.right, bottom), outB, guides);
      canvas.drawCircle(
          outA,
          9,
          handle
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      canvas.drawCircle(outB, 9, handle);
    }
    if (fadeToolActive) {
      handle.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(inX, top), 11, handle);
      canvas.drawCircle(Offset(outX, top), 11, handle);
    }
    if (selectedSlice != null &&
        selectedSlice! >= 0 &&
        selectedSlice! <= sliceMarkers.length) {
      final bounds = <double>[0, ...sliceMarkers, 1];
      final left = selected.left + selected.width * bounds[selectedSlice!];
      final right = selected.left + selected.width * bounds[selectedSlice! + 1];
      canvas.drawRect(Rect.fromLTRB(left, 0, right, size.height),
          Paint()..color = const Color(0x18ffd166));
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.peaks != peaks ||
      old.start != start ||
      old.end != end ||
      old.fadeIn != fadeIn ||
      old.fadeOut != fadeOut ||
      old.fadeInCurve != fadeInCurve ||
      old.fadeOutCurve != fadeOutCurve ||
      old.gain != gain ||
      old.reversed != reversed ||
      old.trimToolActive != trimToolActive ||
      old.fadeToolActive != fadeToolActive ||
      old.sliceToolActive != sliceToolActive ||
      old.sliceMarkers != sliceMarkers ||
      old.selectedSlice != selectedSlice ||
      old.playhead != playhead;
}
