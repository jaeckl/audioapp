part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateSavecurveresource
    on _AutomationEditorScreenState {
  Future<void> _saveCurveResource() async {
    final name = await CurveLibraryDialog.requestName(context);
    if (name == null || !mounted) return;
    final length = math.max(_clipLengthBeats, 1.0e-6);
    await CurveLibraryStore.save(CurveLibraryResource(
      id: 'curve:user:${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      positions: _points
          .map((point) => (point.beat / length).clamp(0.0, 1.0))
          .toList(),
      values: _points.map((point) => point.value.clamp(0.0, 1.0)).toList(),
      shapes: List<int>.filled(_points.length, 0),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved curve “$name”')),
      );
    }
  }
}
