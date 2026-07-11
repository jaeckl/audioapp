part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateCommittrimOperation on _SamplerWaveformViewState {
void _commitTrim() => widget.onTrimChanged?.call(_localTrimStart, _localTrimEnd);
}
