part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateOndragupdateOperation on _SamplerWaveformViewState {
void _onDragUpdate(double x, double width) {
    if (_drag == null) {
      return;
    }
    setState(() {
      final sec = _secFromDx(x, width);
      switch (_drag!) {
        case _WaveformDrag.trimStart:
          _localTrimStart = sec.clamp(0.0, _localTrimEnd - _minSpanSec);
        case _WaveformDrag.trimEnd:
          _localTrimEnd = sec.clamp(_localTrimStart + _minSpanSec, _dur);
        case _WaveformDrag.regionStart:
          _localRegionStart = sec.clamp(0.0, _localRegionEnd - _minSpanSec);
        case _WaveformDrag.regionEnd:
          _localRegionEnd = sec.clamp(_localRegionStart + _minSpanSec, _dur);
      }
    });
  }
}
