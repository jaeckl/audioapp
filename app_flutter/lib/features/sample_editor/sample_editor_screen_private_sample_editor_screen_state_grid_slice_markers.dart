part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateGridslicemarkersOperation on _SampleEditorScreenState {
List<double> _gridSliceMarkers() {
    final stepBeats = switch (sliceGridDivision) {
      SampleEditSnap.off => .25,
      SampleEditSnap.half => 2.0,
      SampleEditSnap.quarter => 1.0,
      SampleEditSnap.eighth => .5,
      SampleEditSnap.sixteenth => .25,
      SampleEditSnap.thirtySecond => .125,
    };
    final natural = math.max(.001, widget.clip.effectiveNaturalLengthBeats);
    final startBeat = start * natural;
    final endBeat = end * natural;
    final markers = <double>[];
    final window = math.max(.001, end - start);
    final firstBeat = (startBeat / stepBeats).ceil() * stepBeats;
    for (var beat = firstBeat; beat < endBeat - .0001; beat += stepBeats) {
      if (beat <= startBeat + .0001) continue;
      final sourcePosition = (beat / natural).clamp(start, end);
      markers.add(((sourcePosition - start) / window).clamp(.001, .999));
    }
    return markers;
  }
}
