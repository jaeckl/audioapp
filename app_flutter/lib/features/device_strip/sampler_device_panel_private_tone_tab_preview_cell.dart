part of 'sampler_device_panel.dart';

extension _ToneTabPreviewcell on _ToneTab {
  Widget _previewCell(SamplerEnvelopePreview preview) {
    return _toneCell(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: IgnorePointer(
          child: preview,
        ),
      ),
    );
  }
}
