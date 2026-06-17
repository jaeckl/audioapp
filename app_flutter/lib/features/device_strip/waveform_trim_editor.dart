import 'package:flutter/material.dart';

import '../sample_library/sample_library_screen.dart';

/// Trim handles on a waveform — fullscreen editor only (keeps strip uncluttered).
class WaveformTrimEditor extends StatefulWidget {
  const WaveformTrimEditor({
    super.key,
    required this.peaks,
    required this.durationSec,
    required this.trimStartSec,
    required this.trimEndSec,
    required this.onTrimChanged,
    this.waveColor = const Color(0xFF6EC9A0),
  });

  final List<double> peaks;
  final double durationSec;
  final double trimStartSec;
  final double trimEndSec;
  final void Function(double startSec, double endSec) onTrimChanged;
  final Color waveColor;

  @override
  State<WaveformTrimEditor> createState() => _WaveformTrimEditorState();
}

class _WaveformTrimEditorState extends State<WaveformTrimEditor> {
  static const double _handleWidth = 28;

  late double _start;
  late double _end;
  _TrimDrag? _drag;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant WaveformTrimEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_drag == null) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    final dur = widget.durationSec > 0 ? widget.durationSec : 1.0;
    _start = widget.trimStartSec.clamp(0, dur);
    _end = widget.trimEndSec > 0 ? widget.trimEndSec.clamp(_start + 0.01, dur) : dur;
  }

  double _secFromDx(double dx, double width) {
    final dur = widget.durationSec > 0 ? widget.durationSec : 1.0;
    return (dx / width * dur).clamp(0, dur);
  }

  void _commit() {
    widget.onTrimChanged(_start, _end);
  }

  @override
  Widget build(BuildContext context) {
    final dur = widget.durationSec > 0 ? widget.durationSec : 1.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final startX = _start / dur * w;
        final endX = _end / dur * w;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            final x = d.localPosition.dx;
            if ((x - startX).abs() < _handleWidth) {
              _drag = _TrimDrag.start;
            } else if ((x - endX).abs() < _handleWidth) {
              _drag = _TrimDrag.end;
            }
          },
          onHorizontalDragUpdate: (d) {
            if (_drag == null) return;
            setState(() {
              if (_drag == _TrimDrag.start) {
                _start = _secFromDx(d.localPosition.dx, w).clamp(0, _end - 0.02);
              } else {
                _end = _secFromDx(d.localPosition.dx, w).clamp(_start + 0.02, dur);
              }
            });
          },
          onHorizontalDragEnd: (_) {
            _drag = null;
            _commit();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: WaveformPainter(peaks: widget.peaks, color: widget.waveColor),
              ),
              Positioned(
                left: startX,
                width: (endX - startX).clamp(0, w),
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.waveColor.withValues(alpha: 0.12),
                      border: Border.symmetric(
                        vertical: BorderSide(color: widget.waveColor.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
              ),
              _TrimHandle(left: startX - _handleWidth / 2, color: widget.waveColor),
              _TrimHandle(left: endX - _handleWidth / 2, color: widget.waveColor),
            ],
          ),
        );
      },
    );
  }
}

enum _TrimDrag { start, end }

class _TrimHandle extends StatelessWidget {
  const _TrimHandle({required this.left, required this.color});

  final double left;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 4,
      bottom: 4,
      child: Container(
        width: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.drag_handle, size: 16, color: Colors.black87),
      ),
    );
  }
}
