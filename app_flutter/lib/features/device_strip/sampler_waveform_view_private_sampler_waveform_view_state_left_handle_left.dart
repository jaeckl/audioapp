part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateLefthandleleftOperation on _SamplerWaveformViewState {
double _leftHandleLeft(double boundaryX, double width) => boundaryX.clamp(0, width - _handleVisualWidth);
}
