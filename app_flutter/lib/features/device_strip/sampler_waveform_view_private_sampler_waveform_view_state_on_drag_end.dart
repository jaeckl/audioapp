part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateOndragendOperation on _SamplerWaveformViewState {
void _onDragEnd() {
    if (_drag == null) {
      return;
    }
    final drag = _drag!;
    _drag = null;
    if (drag.affectsTrim) {
      _commitTrim();
    } else {
      _commitRegion();
    }
    setState(_syncLocal);
  }
}
