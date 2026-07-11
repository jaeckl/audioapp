part of 'sample_editor_screen.dart';

extension SampleTimelineStatePlayheadxOperation on _SampleTimelineState {
  double _playheadX(double originX, double sourceWidth, double beat) =>
      originX +
      _SampleTimelineState._waveformInsetH +
      _usableSourceWidth(sourceWidth) * _sourceFromPlayheadBeat(beat);
}
