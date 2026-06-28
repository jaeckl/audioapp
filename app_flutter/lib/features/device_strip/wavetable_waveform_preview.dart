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
  int _frameLength = 0;
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
        _frameLength = 0;
        _frameCount = 0;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await rootBundle.load('assets/wavetables/$wtId.wav');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final result = _parseWavFrames(bytes, wtId);
      if (mounted) {
        setState(() {
          _frames = result.$1;
          _frameLength = result.$2;
          _frameCount = result.$3;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _frames = null;
          _frameLength = 0;
          _frameCount = 0;
          _loading = false;
        });
      }
    }
  }

  static (Float64List?, int, int) _parseWavFrames(Uint8List bytes, String wavetableId) {
    final wav = _ParsedWav.tryParse(bytes);
    if (wav == null) return (null, 0, 0);

    final bytesPerSample = wav.bitsPerSample ~/ 8;
    if (bytesPerSample <= 0 || wav.channels <= 0) return (null, 0, 0);

    final sampleCount = wav.dataSize ~/ (bytesPerSample * wav.channels);
    if (sampleCount <= 0) return (null, 0, 0);

    final shape = _WavetableShape.infer(
      sampleCount: sampleCount,
      wavetableId: wavetableId,
      clmBytes: wav.clmBytes,
    );
    if (shape.frameLength <= 1 || shape.frameCount <= 0) return (null, 0, 0);

    final total = shape.frameLength * shape.frameCount;
    if (total > sampleCount) return (null, 0, 0);

    final out = Float64List(total);
    for (int frame = 0; frame < total; ++frame) {
      double mixed = 0.0;
      for (int channel = 0; channel < wav.channels; ++channel) {
        final sampleOffset = wav.dataOffset +
            ((frame * wav.channels + channel) * bytesPerSample);
        mixed += _decodeSample(
          bytes: bytes,
          offset: sampleOffset,
          audioFormat: wav.audioFormat,
          bitsPerSample: wav.bitsPerSample,
        );
      }
      out[frame] = (mixed / wav.channels).clamp(-1.0, 1.0).toDouble();
    }

    return (out, shape.frameLength, shape.frameCount);
  }

  static double _decodeSample({
    required Uint8List bytes,
    required int offset,
    required int audioFormat,
    required int bitsPerSample,
  }) {
    if (offset < 0 || offset >= bytes.length) return 0.0;
    final bd = ByteData.sublistView(bytes);

    if (audioFormat == 1) {
      if (bitsPerSample == 8) {
        return (bytes[offset] - 128.0) / 128.0;
      }
      if (bitsPerSample == 16 && offset + 1 < bytes.length) {
        return bd.getInt16(offset, Endian.little) / 32768.0;
      }
      if (bitsPerSample == 24 && offset + 2 < bytes.length) {
        int raw = bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
        if ((raw & 0x00800000) != 0) raw |= ~0x00ffffff;
        return raw / 8388608.0;
      }
      if (bitsPerSample == 32 && offset + 3 < bytes.length) {
        return bd.getInt32(offset, Endian.little) / 2147483648.0;
      }
      return 0.0;
    }

    if (audioFormat == 3) {
      if (bitsPerSample == 32 && offset + 3 < bytes.length) {
        final value = bd.getFloat32(offset, Endian.little);
        return value.isFinite ? value.clamp(-1.0, 1.0).toDouble() : 0.0;
      }
      if (bitsPerSample == 64 && offset + 7 < bytes.length) {
        final value = bd.getFloat64(offset, Endian.little);
        return value.isFinite ? value.clamp(-1.0, 1.0).toDouble() : 0.0;
      }
    }

    return 0.0;
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
              const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
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

class _ParsedWav {
  const _ParsedWav({
    required this.audioFormat,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.dataOffset,
    required this.dataSize,
    required this.clmBytes,
  });

  final int audioFormat;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final int dataOffset;
  final int dataSize;
  final Uint8List? clmBytes;

  static _ParsedWav? tryParse(Uint8List bytes) {
    if (bytes.length < 12) return null;
    if (!_matches(bytes, 0, 'RIFF') || !_matches(bytes, 8, 'WAVE')) return null;

    final bd = ByteData.sublistView(bytes);
    int audioFormat = 0;
    int channels = 0;
    int sampleRate = 0;
    int bitsPerSample = 0;
    int dataOffset = -1;
    int dataSize = 0;
    Uint8List? clmBytes;

    int offset = 12;
    while (offset + 8 <= bytes.length) {
      final chunkIdOffset = offset;
      final chunkSize = bd.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;
      if (chunkDataOffset > bytes.length || chunkSize > bytes.length - chunkDataOffset) {
        break;
      }

      if (_matches(bytes, chunkIdOffset, 'fmt ') && chunkSize >= 16) {
        audioFormat = bd.getUint16(chunkDataOffset, Endian.little);
        channels = bd.getUint16(chunkDataOffset + 2, Endian.little);
        sampleRate = bd.getUint32(chunkDataOffset + 4, Endian.little);
        bitsPerSample = bd.getUint16(chunkDataOffset + 14, Endian.little);

        if (audioFormat == 0xfffe && chunkSize >= 40) {
          final subFormat = bd.getUint16(chunkDataOffset + 24, Endian.little);
          if (subFormat == 1 || subFormat == 3) {
            audioFormat = subFormat;
          }
        }
      } else if (_matches(bytes, chunkIdOffset, 'data')) {
        if (dataOffset < 0) {
          dataOffset = chunkDataOffset;
          dataSize = chunkSize;
        }
      } else if (_matches(bytes, chunkIdOffset, 'clm ')) {
        clmBytes = Uint8List.sublistView(bytes, chunkDataOffset, chunkDataOffset + chunkSize);
      }

      final nextOffset = chunkDataOffset + chunkSize + (chunkSize.isOdd ? 1 : 0);
      if (nextOffset <= offset) break;
      offset = nextOffset;
    }

    if (channels <= 0 || sampleRate <= 0 || bitsPerSample <= 0 || dataOffset < 0 || dataSize <= 0) {
      return null;
    }
    if (audioFormat != 1 && audioFormat != 3) return null;

    return _ParsedWav(
      audioFormat: audioFormat,
      channels: channels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
      dataOffset: dataOffset,
      dataSize: dataSize,
      clmBytes: clmBytes,
    );
  }

  static bool _matches(Uint8List bytes, int offset, String text) {
    if (offset < 0 || offset + text.length > bytes.length) return false;
    for (int i = 0; i < text.length; ++i) {
      if (bytes[offset + i] != text.codeUnitAt(i)) return false;
    }
    return true;
  }
}

class _WavetableShape {
  const _WavetableShape(this.frameLength, this.frameCount);

  static const int serumFrameLength = 2048;
  static const int maxSerumFrames = 256;

  final int frameLength;
  final int frameCount;

  static _WavetableShape infer({
    required int sampleCount,
    required String wavetableId,
    required Uint8List? clmBytes,
  }) {
    final clmFrameLength = _frameLengthFromClm(clmBytes);
    if (_validShape(clmFrameLength, sampleCount)) {
      return _WavetableShape(clmFrameLength, sampleCount ~/ clmFrameLength);
    }

    final explicit = _explicitCountLengthFromName(wavetableId, sampleCount);
    if (explicit != null) return explicit;

    final trailing = _trailingFrameCountFromName(wavetableId, sampleCount);
    if (trailing != null) return trailing;

    if (_validShape(serumFrameLength, sampleCount)) {
      return _WavetableShape(serumFrameLength, sampleCount ~/ serumFrameLength);
    }

    const fallbackFrameLengths = [1024, 512, 256, 128, 64, 32];
    for (final frameLength in fallbackFrameLengths) {
      if (_validShape(frameLength, sampleCount)) {
        return _WavetableShape(frameLength, sampleCount ~/ frameLength);
      }
    }

    return _WavetableShape(sampleCount, 1);
  }

  static bool _validShape(int frameLength, int sampleCount) {
    if (frameLength <= 0 || sampleCount <= 0 || sampleCount % frameLength != 0) return false;
    final frameCount = sampleCount ~/ frameLength;
    return frameCount >= 1 && frameCount <= maxSerumFrames;
  }

  static int _frameLengthFromClm(Uint8List? clmBytes) {
    if (clmBytes == null || clmBytes.isEmpty) return 0;
    final afterMarker = _firstIntAfterMarker(clmBytes, '<!>');
    if (afterMarker > 0) return afterMarker;
    return _firstIntAfterMarker(clmBytes, '');
  }

  static int _firstIntAfterMarker(Uint8List bytes, String marker) {
    int start = 0;
    if (marker.isNotEmpty && bytes.length >= marker.length) {
      for (int i = 0; i + marker.length <= bytes.length; ++i) {
        var matched = true;
        for (int j = 0; j < marker.length; ++j) {
          if (bytes[i + j] != marker.codeUnitAt(j)) {
            matched = false;
            break;
          }
        }
        if (matched) {
          start = i + marker.length;
          break;
        }
      }
    }

    for (int i = start; i < bytes.length; ++i) {
      final b = bytes[i];
      if (b < 48 || b > 57) continue;
      var value = 0;
      while (i < bytes.length && bytes[i] >= 48 && bytes[i] <= 57) {
        value = value * 10 + (bytes[i] - 48);
        if (value > 65536) return 0;
        ++i;
      }
      return value;
    }
    return 0;
  }

  static _WavetableShape? _explicitCountLengthFromName(String name, int sampleCount) {
    final base = _baseNameWithoutExtension(name);
    final matches = RegExp(r'(\d+)[xX](\d+)').allMatches(base);
    for (final match in matches) {
      final frameCount = int.tryParse(match.group(1)!);
      final frameLength = int.tryParse(match.group(2)!);
      if (frameCount == null || frameLength == null) continue;
      if (frameCount > 0 && frameLength > 0 && frameCount * frameLength == sampleCount &&
          frameCount <= maxSerumFrames) {
        return _WavetableShape(frameLength, frameCount);
      }
    }
    return null;
  }

  static _WavetableShape? _trailingFrameCountFromName(String name, int sampleCount) {
    final base = _baseNameWithoutExtension(name);
    final match = RegExp(r'[_-](\d+)$').firstMatch(base);
    if (match == null) return null;

    final frameCount = int.tryParse(match.group(1)!);
    if (frameCount == null || frameCount <= 0 || frameCount > maxSerumFrames) return null;
    if (sampleCount % frameCount != 0) return null;

    final frameLength = sampleCount ~/ frameCount;
    if (frameLength < 32 || frameLength > serumFrameLength || !_isPowerOfTwo(frameLength)) return null;
    return _WavetableShape(frameLength, frameCount);
  }

  static bool _isPowerOfTwo(int value) {
    return value > 0 && (value & (value - 1)) == 0;
  }

  static String _baseNameWithoutExtension(String name) {
    final slash = math.max(name.lastIndexOf('/'), name.lastIndexOf('\\'));
    final start = slash < 0 ? 0 : slash + 1;
    final dot = name.lastIndexOf('.');
    final end = dot > start ? dot : name.length;
    return name.substring(start, end);
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

    final data = frames;
    if (data == null || frameCount <= 0 || frameLength <= 1) {
      _drawPlaceholder(canvas, size);
      return;
    }

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(6),
      ),
    );

    final activeFrame = (wtPosition * (frameCount - 1)).clamp(
      0.0,
      (frameCount - 1).toDouble(),
    ).toDouble();
    final activeIndex = activeFrame.round().clamp(0, frameCount - 1);

    final targetVisible = math.max(8, math.min(48, (size.width / 5.0).round()));
    final visibleCount = math.min(frameCount, targetVisible);

    final stackDepthY = size.height * 0.28;
    final stackDepthX = math.min(size.width * 0.12, 18.0);

    final verticalPad = size.height * 0.04;
    final amplitude = math.max(
      2.0,
      (size.height - stackDepthY - verticalPad * 2.0) * 0.5,
    );

    final centerBaseY = size.height * 0.5;
    final xPad = stackDepthX * 0.55 + 2.0;
    final pointCount = math.max(24, math.min(frameLength, math.min(256, (size.width * 2).round())));

    void drawFrame({
      required int frameIndex,
      required double depth,
      required bool active,
    }) {
      final offset = frameIndex * frameLength;
      if (offset + frameLength > data.length) return;

      final yShift = _lerp(-stackDepthY * 0.5, stackDepthY * 0.5, depth);
      final xShift = _lerp(stackDepthX * 0.5, -stackDepthX * 0.5, depth);

      final centerY = centerBaseY + yShift;
      final startX = xPad + xShift;
      final endX = size.width - xPad + xShift;

      final activeDistance = (frameIndex - activeFrame).abs() / math.max(frameCount - 1, 1);
      final activeGlow = math.pow((1.0 - activeDistance).clamp(0.0, 1.0), 4.0).toDouble();

      final alpha = active
          ? 0.95
          : (0.08 + depth * 0.22 + activeGlow * 0.18).clamp(0.08, 0.5).toDouble();

      final strokeWidth = active ? 2.0 : _lerp(0.55, 1.1, depth);

      final path = Path();
      for (int p = 0; p < pointCount; ++p) {
        final t = pointCount <= 1 ? 0.0 : p / (pointCount - 1);
        final sampleIndex = math.min(frameLength - 1, (t * (frameLength - 1)).round());
        final x = _lerp(startX, endX, t);
        final sample = data[offset + sampleIndex];
        final y = centerY - sample * amplitude;

        if (p == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final fillPath = Path.from(path)
        ..lineTo(endX, centerY)
        ..lineTo(startX, centerY)
        ..close();

      final fillPaint = Paint()
        ..color = accent.withValues(alpha: active ? 0.16 : alpha * 0.18)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final strokePaint = Paint()
        ..color = accent.withValues(alpha: alpha)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, strokePaint);
    }

    for (int i = 0; i < visibleCount; ++i) {
      final depth = visibleCount <= 1 ? 1.0 : i / (visibleCount - 1);
      final frameIndex = visibleCount <= 1
          ? 0
          : ((i / (visibleCount - 1)) * (frameCount - 1)).round();

      if (frameIndex == activeIndex) continue;
      drawFrame(frameIndex: frameIndex, depth: depth, active: false);
    }

    final activeDepth = frameCount <= 1 ? 1.0 : activeFrame / (frameCount - 1);
    drawFrame(frameIndex: activeIndex, depth: activeDepth, active: true);

    canvas.restore();
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    const int pts = 128;

    final paint = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final midY = size.height / 2;
    final h = size.height * 0.35;
    final path = Path();

    for (int i = 0; i < pts; ++i) {
      final x = (i / (pts - 1)) * size.width;
      final t = i / pts;
      final y = midY - _fastSin(t * 6.2832) * h;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  static double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
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
