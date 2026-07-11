part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStatePickhandleOperation on _SamplerWaveformViewState {
_WaveformDrag? _pickHandle(double x, double y, double width, double height) {
    _WaveformDrag? best;
    var bestDist = _handleHitRadius;

    void consider(_WaveformDrag kind, double dist) {
      if (dist < bestDist) {
        bestDist = dist;
        best = kind;
      }
    }

    final trimStartX = _trimStart / _dur * width;
    final trimEndX = _trimEnd / _dur * width;
    final yMin = _handleVerticalInset;
    final yMax = height - _handleVerticalInset;

    if (_showTrimHandles) {
      if (_hitLeftHandle(x, y, trimStartX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.trimStart, (x - (trimStartX + _handleVisualWidth / 2)).abs());
      }
      if (_hitRightHandle(x, y, trimEndX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.trimEnd, (x - (trimEndX - _handleVisualWidth / 2)).abs());
      }
    }

    if (_showLoopHandles) {
      final regionStartX = _regionStart / _dur * width;
      final regionEndX = _regionEnd / _dur * width;
      if (_hitLeftHandle(x, y, regionStartX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.regionStart, (x - (regionStartX + _handleVisualWidth / 2)).abs());
      }
      if (_hitRightHandle(x, y, regionEndX, width, height, yMin, yMax)) {
        consider(_WaveformDrag.regionEnd, (x - (regionEndX - _handleVisualWidth / 2)).abs());
      }
    }

    return best;
  }
}
