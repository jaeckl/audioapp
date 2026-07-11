part of 'wavetable_waveform_preview.dart';

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
    if (frameLength <= 0 || sampleCount <= 0 || sampleCount % frameLength != 0)
      return false;
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

  static _WavetableShape? _explicitCountLengthFromName(
      String name, int sampleCount) {
    final base = _baseNameWithoutExtension(name);
    final matches = RegExp(r'(\d+)[xX](\d+)').allMatches(base);
    for (final match in matches) {
      final frameCount = int.tryParse(match.group(1)!);
      final frameLength = int.tryParse(match.group(2)!);
      if (frameCount == null || frameLength == null) continue;
      if (frameCount > 0 &&
          frameLength > 0 &&
          frameCount * frameLength == sampleCount &&
          frameCount <= maxSerumFrames) {
        return _WavetableShape(frameLength, frameCount);
      }
    }
    return null;
  }

  static _WavetableShape? _trailingFrameCountFromName(
      String name, int sampleCount) {
    final base = _baseNameWithoutExtension(name);
    final match = RegExp(r'[_-](\d+)$').firstMatch(base);
    if (match == null) return null;

    final frameCount = int.tryParse(match.group(1)!);
    if (frameCount == null || frameCount <= 0 || frameCount > maxSerumFrames)
      return null;
    if (sampleCount % frameCount != 0) return null;

    final frameLength = sampleCount ~/ frameCount;
    if (frameLength < 32 ||
        frameLength > serumFrameLength ||
        !_isPowerOfTwo(frameLength)) return null;
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
