part of 'sample_editor_screen.dart';

extension SampleTimelineStateSourcefromplayheadbeatOperation on _SampleTimelineState {
double _sourceFromPlayheadBeat(double beat) {
    final contentLen = widget.playbackContentLengthBeats;
    if (contentLen <= 0) return widget.start;
    final progress = (beat / contentLen).clamp(0.0, 1.0);
    return widget.reversed
        ? widget.end - progress * _sourceSpan
        : widget.start + progress * _sourceSpan;
  }
}
