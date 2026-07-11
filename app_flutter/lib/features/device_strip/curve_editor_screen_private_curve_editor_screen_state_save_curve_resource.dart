part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateSavecurveresource on _CurveEditorScreenState {
  Future<void> _saveCurveResource() async {
    final name = await CurveLibraryDialog.requestName(context);
    if (name == null || !mounted) return;
    await CurveLibraryStore.save(CurveLibraryResource(
      id: 'curve:user:${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      positions: _positions.map((value) => value.clamp(0.0, 1.0)).toList(),
      values: _values
          .map((value) => _polarity == 0
              ? ((value + 1) * 0.5).clamp(0.0, 1.0)
              : value.clamp(0.0, 1.0))
          .toList(),
      shapes: List<int>.of(_shapes),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved curve “$name”')),
      );
    }
  }
}
