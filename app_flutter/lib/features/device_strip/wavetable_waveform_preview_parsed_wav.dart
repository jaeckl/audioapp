part of 'wavetable_waveform_preview.dart';

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
      if (chunkDataOffset > bytes.length ||
          chunkSize > bytes.length - chunkDataOffset) {
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
        clmBytes = Uint8List.sublistView(
            bytes, chunkDataOffset, chunkDataOffset + chunkSize);
      }

      final nextOffset =
          chunkDataOffset + chunkSize + (chunkSize.isOdd ? 1 : 0);
      if (nextOffset <= offset) break;
      offset = nextOffset;
    }

    if (channels <= 0 ||
        sampleRate <= 0 ||
        bitsPerSample <= 0 ||
        dataOffset < 0 ||
        dataSize <= 0) {
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
