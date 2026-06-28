import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WavetableWaveformPreview extends StatefulWidget {
  const WavetableWaveformPreview({
    super.key,
    this.accent = const Color(0xFF3B82F6),
    this.showLabel = false,
    this.label,
    this.onTap,
    this.wavetableId,
    this.wtPosition,
  });

  final Color accent;
  final bool showLabel;
  final String? label;
  final VoidCallback? onTap;
  final String? wavetableId;
  final double? wtPosition;

  @override
  State<WavetableWaveformPreview> createState() => _WavetableWaveformPreviewState();
}

class _WavetableWaveformPreviewState extends State<WavetableWaveformPreview> {
  Float64List? _frames;
  int _frameLength = 64;
  int _frameCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadWavetable();
  }

  @override
  void didUpdateWidget(covariant WavetableWaveformPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wavetableId != oldWidget.wavetableId) {
      _loadWavetable();
    }
  }

  Future<void> _loadWavetable() async {
    final wtId = widget.wavetableId;
    if (wtId == null || wtId.isEmpty) {
      setState(() {
        _frames = null;
        _frameCount = 0;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await rootBundle.load('assets/wavetables/$wtId.wav');
      final bytes = data.buffer.asUint8List();
      final result = _parseWavFrames(bytes);
      if (mounted) {
        setState(() {
          _frames = result.$1;
          _frameLength = result.$2;
          _frameCount = result.$3;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static (Float64List?, int, int) _parseWavFrames(Uint8List bytes) {
    if (bytes.length < 44) return (null, 0, 0);
    if (bytes[0] != 0x52 || bytes[1] != 0x49 || bytes[2] != 0x46 || bytes[3] != 0x46) return (null, 0, 0);
    final bitsPerSample = bytes[34] | (bytes[35] << 8);
    if (bitsPerSample != 16) return (null, 0, 0);
    final dataSize = bytes[40] | (bytes[41] << 8) | (bytes[42] << 16) | (bytes[43] << 24);
    final sampleCount = dataSize ~/ 2;
    if (sampleCount <= 0) return (null, 0, 0);

    const frameLen = 32;
    final frames = sampleCount ~/ frameLen;
    if (frames <= 0) return (null, 0, 0);

    final total = frames * frameLen;
    final data = Float64List(total);
    for (int i = 0; i < total; ++i) {
      final idx = 44 + i * 2;
      if (idx + 1 >= bytes.length) break;
      final sample = (bytes[idx] | (bytes[idx + 1] << 8)).toInt();
      data[i] = sample / 32768.0;
    }
    return (data, frameLen, frames);
  }

  @override
  Widget build(BuildContext context) {
    final displayFrames = _frames;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: widget.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            if (_loading)
              const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
            else
              CustomPaint(
                size: Size.infinite,
                painter: _Wavetable3DPainter(
                  accent: widget.accent,
                  frames: displayFrames,
                  frameLength: _frameLength,
                  frameCount: _frameCount,
                  wtPosition: widget.wtPosition ?? 0.0,
                ),
              ),
            if (widget.showLabel && widget.label != null)
              Positioned(
                left: 6,
                bottom: 4,
                child: Text(
                  widget.label!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Wavetable3DPainter extends CustomPainter {
  _Wavetable3DPainter({
    required this.accent,
    this.frames,
    required this.frameLength,
    required this.frameCount,
    required this.wtPosition,
  });

  final Color accent;
  final Float64List? frames;
  final int frameLength;
  final int frameCount;
  final double wtPosition;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (frames == null || frameCount <= 0 || frameLength <= 0) {
      _drawPlaceholder(canvas, size);
      return;
    }

    final activeFrame = (wtPosition * (frameCount - 1)).clamp(0.0, (frameCount - 1).toDouble());
    final maxVisibleFrames = (size.height / 3.0).ceil().clamp(4, 64);
    final step = math.max(1, frameCount ~/ maxVisibleFrames);
    final visibleCount = (frameCount / step).ceil();
    final frameHeight = size.height / (visibleCount + 1);
    final padY = frameHeight * 0.5;

    for (int vi = 0; vi < visibleCount; ++vi) {
      final fi = (vi * step).clamp(0, frameCount - 1);
      final centerY = padY + vi * frameHeight;
      final isActive = fi == activeFrame.round();
      final dist = (fi - activeFrame).abs() / math.max(frameCount.toDouble(), 1.0);
      final alpha = isActive ? 0.9 : (0.08 + 0.3 * (1.0 - dist * 2.0).clamp(0.0, 1.0));
      final strokeW = isActive ? 2.0 : 0.5;

      final offset = fi * frameLength;
      final paint = Paint()
        ..color = accent.withValues(alpha: alpha)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int s = 0; s < frameLength; ++s) {
        final x = (s / (frameLength - 1)) * size.width;
        final sample = frames![offset + s];
        final y = centerY + sample * (frameHeight * 0.5);
        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    const int pts = 128;
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final midY = size.height / 2;
    final h = size.height * 0.5;
    final path = Path();
    for (int i = 0; i < pts; ++i) {
      final x = (i / (pts - 1)) * size.width;
      final t = i / pts;
      final y = midY + _fastSin(t * 6.2832) * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  static double _fastSin(double x) {
    double y = x - (x / 6.2832).floor() * 6.2832;
    if (y > 3.1416) y -= 6.2832;
    final y2 = y * y;
    return y * (1.0 - y2 * (1.0 / 6.0 - y2 * (1.0 / 120.0 - y2 / 5040.0)));
  }

  @override
  bool shouldRepaint(covariant _Wavetable3DPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.frames != frames ||
        oldDelegate.frameLength != frameLength ||
        oldDelegate.frameCount != frameCount ||
        oldDelegate.wtPosition != wtPosition;
  }
}
