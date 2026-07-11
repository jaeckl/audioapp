part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateRighthandleleftOperation on _SamplerWaveformViewState {
double _rightHandleLeft(double boundaryX, double width) => (boundaryX - _handleVisualWidth).clamp(0, width - _handleVisualWidth);
}
