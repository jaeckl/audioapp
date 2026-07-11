part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateTakeregionindexatbeatOperation on _SampleEditorScreenState {
int? _takeRegionIndexAtBeat(double beat) {
    for (var i = 0; i < takeRegions.length; i++) {
      final region = takeRegions[i];
      final isLast = i == takeRegions.length - 1;
      if (beat >= region.startBeat &&
          (beat < region.endBeat || (isLast && beat <= region.endBeat))) {
        return i;
      }
    }
    return null;
  }
}
