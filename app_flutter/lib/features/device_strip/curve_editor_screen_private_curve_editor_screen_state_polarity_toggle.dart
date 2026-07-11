part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStatePolaritytoggle on _CurveEditorScreenState {
  Widget _polarityToggle() {
    final isBipolar = _polarity == 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _polarity = isBipolar ? 1 : 0;
            for (var i = 0; i < _values.length; i++) {
              _values[i] = _valueClamp(_values[i]);
            }
          });
          _syncToBridge();
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isBipolar
                  ? _accent.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            color: isBipolar
                ? _accent.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
          ),
          alignment: Alignment.center,
          child: Text(
            isBipolar ? 'Bi' : 'Uni',
            style: TextStyle(
              color: isBipolar ? _accent : Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
