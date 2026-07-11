part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSanitizemarkersOperation on _SampleEditorScreenState {
List<double> _sanitizeMarkers(Iterable<double> markers) {
    final sorted = markers
        .map((marker) => marker.clamp(.001, .999))
        .toSet()
        .toList()
      ..sort();
    final kept = <double>[];
    for (final marker in sorted) {
      if (kept.isEmpty || marker - kept.last >= sliceMinGap) {
        kept.add(marker);
      }
      if (kept.length >= 31) break;
    }
    return kept;
  }
}
