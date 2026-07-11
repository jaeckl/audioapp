part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateCreateregionatOperation on _SamplerWaveformViewState {
void _createRegionAt(double tapSec) {
    final halfWidth = _dur * 0.1;
    var start = (tapSec - halfWidth).clamp(0.0, _dur);
    var end = (tapSec + halfWidth).clamp(0.0, _dur);
    if (end - start < 0.05) {
      end = (start + 0.05).clamp(0.0, _dur);
    }
    widget.onRegionChanged?.call(start, end);
  }
}
