part of 'timeline_marker_layer.dart';

class TimelineViewportScrollController {
  void Function(double beat)? _reveal;
  void Function(double beat, {required bool immediate})? _catchUpOnPlay;
  void Function(double beat)? _followIfNeeded;

  void bind({
    void Function(double beat)? reveal,
    void Function(double beat, {required bool immediate})? catchUpOnPlay,
    void Function(double beat)? followIfNeeded,
  }) {
    _reveal = reveal;
    _catchUpOnPlay = catchUpOnPlay;
    _followIfNeeded = followIfNeeded;
  }

  void revealPlayheadAtViewportOrigin(double beat) => _reveal?.call(beat);

  void catchUpPlayheadOnPlay(double beat, {bool immediate = true}) =>
      _catchUpOnPlay?.call(beat, immediate: immediate);

  void followPlayheadIfNeeded(double beat) => _followIfNeeded?.call(beat);
}
