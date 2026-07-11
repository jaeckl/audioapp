part of 'sampler_waveform_view.dart';

extension SamplerWaveformViewStateOndragstartOperation on _SamplerWaveformViewState {
void _onDragStart(double x, double y, double width, double height) {
    if (widget.peaks.isEmpty) {
      return;
    }
    _syncLocal();
    final picked = _pickHandle(x, y, width, height);
    if (picked == null) {
      return;
    }
    setState(() => _drag = picked);
  }
}
