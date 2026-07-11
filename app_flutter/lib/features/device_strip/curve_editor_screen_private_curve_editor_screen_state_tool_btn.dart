part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateToolbtn on _CurveEditorScreenState {
  Widget _toolBtn(IconData icon, IconData activeIcon, CurveEditorTool t) {
    final active = _tool == t;
    return Material(
      color: active ? _accent.withValues(alpha: 0.15) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _tool = t;
          _paintShape = null;
          _selectedIndices.clear();
        }),
        child: SizedBox(
          width: 40,
          height: 48,
          child: Icon(active ? activeIcon : icon,
              size: 20, color: active ? _accent : Colors.white54),
        ),
      ),
    );
  }
}
