part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateBuildtoolbar on _CurveEditorScreenState {
  Widget _buildToolbar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          _toolBtn(Icons.pan_tool_alt_outlined, Icons.pan_tool_alt,
              CurveEditorTool.select),
          _toolBtn(Icons.edit_outlined, Icons.edit, CurveEditorTool.draw),
          _toolBtn(Icons.auto_fix_high_outlined, Icons.auto_fix_high,
              CurveEditorTool.erase),
          const SizedBox(width: 4),
          // Separator
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 4),
          for (final shape in const [
            AutomationCurveShape.rampUp,
            AutomationCurveShape.sine,
            AutomationCurveShape.triangle,
            AutomationCurveShape.sawUp,
            AutomationCurveShape.square,
          ])
            _shapeBtn(shape),
          const Spacer(),
          _polarityToggle(),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _resetToDefault,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 16, color: Colors.white54),
                    SizedBox(width: 4),
                    Text('Reset',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
