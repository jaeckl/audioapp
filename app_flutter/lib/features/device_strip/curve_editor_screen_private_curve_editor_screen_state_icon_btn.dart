part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateIconbtn on _CurveEditorScreenState {
  Widget _iconBtn(IconData icon, bool enabled, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 48,
          child: Icon(icon,
              size: 20,
              color: enabled ? _accent : Colors.white.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
