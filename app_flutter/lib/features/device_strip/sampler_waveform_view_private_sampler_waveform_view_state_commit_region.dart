part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateCommitregionOperation on _SamplerWaveformViewState {
void _commitRegion() => widget.onRegionChanged?.call(_localRegionStart, _localRegionEnd);
}
