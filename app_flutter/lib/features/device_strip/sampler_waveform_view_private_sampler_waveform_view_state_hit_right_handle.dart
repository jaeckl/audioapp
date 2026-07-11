part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateHitrighthandleOperation on _SamplerWaveformViewState {
bool _hitRightHandle(
    double x,
    double y,
    double boundaryX,
    double width,
    double height,
    double top,
    double bottom,
  ) {
    if (y < top || y > bottom) return false;
    final gripCenterX = boundaryX - _handleVisualWidth / 2;
    return (x - gripCenterX).abs() <= _handleHitRadius;
  }
}
