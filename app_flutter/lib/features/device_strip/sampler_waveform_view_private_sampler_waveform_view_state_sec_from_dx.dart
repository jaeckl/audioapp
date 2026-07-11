part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateSecfromdxOperation on _SamplerWaveformViewState {
double _secFromDx(double dx, double width) => (dx / width * _dur).clamp(0, _dur);
}
