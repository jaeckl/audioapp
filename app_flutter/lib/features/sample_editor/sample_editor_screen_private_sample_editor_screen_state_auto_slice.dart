part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateAutosliceOperation on _SampleEditorScreenState {
void _autoSlice() {
    var usedFallback = false;
    var generated = switch (sliceAutoMode) {
      _SliceAutoMode.transient => _detectTransientMarkers(),
      _SliceAutoMode.even => _evenSliceMarkers(),
      _SliceAutoMode.grid => _gridSliceMarkers(),
    };
    if (sliceAutoMode == _SliceAutoMode.transient && generated.length < 2) {
      generated = _evenSliceMarkers();
      usedFallback = true;
    }
    final shouldSnapGenerated = sliceAutoMode == _SliceAutoMode.transient &&
        editSnap.snap != SampleEditSnap.off;
    final snapped = !shouldSnapGenerated
        ? generated
        : generated.map(editSnap.snapSource).toList();
    final next = sliceReplaceExisting
        ? _sanitizeMarkers(snapped)
        : _sanitizeMarkers([...sliceMarkers, ...snapped]);
    final cutCount = next.length;
    setState(() {
      sliceMarkers = next;
      tool = _SampleTool.slice;
      selectedMarker = null;
      selectedSlice = null;
      sliceStatus = usedFallback
          ? 'Few transients found. Used even slices.'
          : cutCount == 0
              ? 'No slice markers created.'
              : 'Created $cutCount slice markers.';
    });
    unawaited(_saveSlices());
  }
}
