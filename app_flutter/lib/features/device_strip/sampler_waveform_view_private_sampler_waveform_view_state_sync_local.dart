part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateSynclocalOperation on _SamplerWaveformViewState {
void _syncLocal() {
    _localTrimStart = widget.trimStartSec.clamp(0, _dur);
    _localTrimEnd = widget.trimEndSec > 0 ? widget.trimEndSec.clamp(_localTrimStart + _minSpanSec, _dur) : _dur;
    _localRegionStart = widget.regionStartSec.clamp(0, _dur - _minSpanSec);
    _localRegionEnd = widget.regionEndSec > 0 ? widget.regionEndSec.clamp(_localRegionStart + _minSpanSec, _dur) : 0;
  }
}
