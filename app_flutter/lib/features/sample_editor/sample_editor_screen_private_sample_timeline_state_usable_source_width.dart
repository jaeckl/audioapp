part of 'sample_editor_screen.dart';

extension SampleTimelineStateUsablesourcewidthOperation
    on _SampleTimelineState {
  double _usableSourceWidth(double sourceWidth) => math.max(
        1.0,
        sourceWidth - _SampleTimelineState._waveformInsetH * 2,
      );
}
