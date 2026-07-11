part of 'sample_editor_screen.dart';

extension SampleTimelineStatePlayheadbeatfromsourceOperation on _SampleTimelineState {
double _playheadBeatFromSource(double sourcePos) {
    final contentLen = widget.playbackContentLengthBeats;
    if (contentLen <= 0) return 0;
    final clamped = sourcePos.clamp(widget.start, widget.end);
    final progress = widget.reversed
        ? (widget.end - clamped) / _sourceSpan
        : (clamped - widget.start) / _sourceSpan;
    return progress.clamp(0.0, 1.0) * contentLen;
  }
}
