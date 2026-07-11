part of 'wavetable_waveform_preview.dart';

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
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
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

  static (Float64List?, int, int) _parseWavFrames(
      Uint8List bytes, String wavetableId) {
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
        int raw = bytes[offset] |
            (bytes[offset + 1] << 8) |
            (bytes[offset + 2] << 16);
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
