part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateLoadcurveresource
    on _AutomationEditorScreenState {
  Future<void> _loadCurveResource() async {
    final resource = await CurveLibraryDialog.pick(context);
    if (resource == null || !mounted || resource.positions.length < 2) return;
    _pushUndo();
    setState(() {
      _points = [
        for (var i = 0;
            i < resource.positions.length && i < resource.values.length;
            i++)
          AutomationPointSnapshot(
            beat: resource.positions[i].clamp(0.0, 1.0) * _clipLengthBeats,
            value: resource.values[i].clamp(0.0, 1.0),
          ),
      ]..sort((a, b) => a.beat.compareTo(b.beat));
      _clearTransientSelection();
    });
    await _persistPoints();
  }
}
