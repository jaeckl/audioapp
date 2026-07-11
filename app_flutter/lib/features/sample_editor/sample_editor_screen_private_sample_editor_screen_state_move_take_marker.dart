part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateMovetakemarkerOperation on _SampleEditorScreenState {
void _moveTakeMarker(int index, double beat) {
    if (index < 0 || index + 1 >= takeRegions.length) return;
    final left = takeRegions[index];
    final right = takeRegions[index + 1];
    final nextBeat = beat.clamp(left.startBeat + .001, right.endBeat - .001);
    setState(() {
      takeRegions[index] = SampleClipTakeRegionSnapshot(
        startBeat: left.startBeat,
        endBeat: nextBeat,
        takeId: left.takeId,
        sourceStart: left.sourceStart,
      );
      takeRegions[index + 1] = SampleClipTakeRegionSnapshot(
        startBeat: nextBeat,
        endBeat: right.endBeat,
        takeId: right.takeId,
        sourceStart: right.sourceStart + nextBeat - right.startBeat,
      );
      selectedTakeMarker = index;
    });
  }
}
