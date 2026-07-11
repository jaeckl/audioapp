part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateLoadcurveresource on _CurveEditorScreenState {
  Future<void> _loadCurveResource() async {
    final resource = await CurveLibraryDialog.pick(context);
    if (resource == null || !mounted || resource.positions.length < 2) return;
    final count = math.min(resource.positions.length, resource.values.length);
    setState(() {
      _positions = resource.positions
          .take(count)
          .map((value) => value.clamp(0.0, 1.0))
          .toList();
      _values = resource.values.take(count).map((value) {
        final normalized = value.clamp(0.0, 1.0);
        return _polarity == 0 ? normalized * 2 - 1 : normalized;
      }).toList();
      _shapes = [
        for (var i = 0; i < count; i++)
          i < resource.shapes.length ? resource.shapes[i].clamp(0, 2) : 0,
      ];
      _mergeSort();
      _bpCount = _positions.length;
    });
    await _syncToBridge();
  }
}
