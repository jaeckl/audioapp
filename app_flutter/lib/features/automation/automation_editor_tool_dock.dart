import 'package:flutter/material.dart';

import 'automation_editor_metrics.dart';
import 'automation_editor_theme.dart';
import 'automation_curve_shapes.dart';
import 'automation_shape_icon.dart';

part 'automation_editor_tool_dock_dock_button.dart';
part 'automation_editor_tool_dock_shape_dock_button.dart';

class AutomationEditorToolDock extends StatelessWidget {
  const AutomationEditorToolDock({
    super.key,
    required this.tool,
    required this.canUndo,
    required this.canRedo,
    required this.canInsert,
    required this.canDeleteMarked,
    required this.onToolChanged,
    required this.onInsertTap,
    required this.onDeleteMarkedTap,
    required this.onUndo,
    required this.onRedo,
    required this.previewPlaying,
    required this.onPreviewPlayStop,
    required this.activeShape,
    required this.onShapeSelected,
  });

  final AutomationEditorTool tool;
  final bool canUndo;
  final bool canRedo;
  final bool canInsert;
  final bool canDeleteMarked;
  final ValueChanged<AutomationEditorTool> onToolChanged;
  final VoidCallback onInsertTap;
  final VoidCallback onDeleteMarkedTap;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool previewPlaying;
  final VoidCallback onPreviewPlayStop;
  final AutomationCurveShape? activeShape;
  final ValueChanged<AutomationCurveShape> onShapeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SizedBox(
        height: AutomationEditorMetrics.toolDockHeight,
        child: Row(
          children: [
            _DockButton(
              icon: Icons.pan_tool_alt_outlined,
              activeIcon: Icons.pan_tool_alt,
              active: tool == AutomationEditorTool.select,
              onTap: () => onToolChanged(AutomationEditorTool.select),
            ),
            _DockButton(
              icon: Icons.gesture,
              activeIcon: Icons.gesture,
              active: tool == AutomationEditorTool.draw,
              onTap: () => onToolChanged(AutomationEditorTool.draw),
            ),
            for (final shape in const [
              AutomationCurveShape.rampUp,
              AutomationCurveShape.sine,
              AutomationCurveShape.triangle,
              AutomationCurveShape.sawUp,
              AutomationCurveShape.square,
            ])
              _ShapeDockButton(
                shape: shape,
                active: activeShape == shape,
                onTap: () => onShapeSelected(shape),
              ),
            _DockButton(
              icon: Icons.delete_sweep_outlined,
              activeIcon: Icons.delete_sweep,
              active: tool == AutomationEditorTool.multiErase,
              onTap: () => onToolChanged(AutomationEditorTool.multiErase),
            ),
            if (tool == AutomationEditorTool.multiErase)
              _DockButton(
                icon: Icons.delete_outline,
                activeIcon: Icons.delete,
                active: false,
                enabled: canDeleteMarked,
                onTap: onDeleteMarkedTap,
              ),
            const Spacer(),
            _DockButton(
              icon: Icons.play_arrow,
              activeIcon: Icons.stop,
              active: previewPlaying,
              onTap: onPreviewPlayStop,
            ),
            _DockButton(
              icon: Icons.undo,
              activeIcon: Icons.undo,
              active: false,
              enabled: canUndo,
              onTap: onUndo,
            ),
            _DockButton(
              icon: Icons.redo,
              activeIcon: Icons.redo,
              active: false,
              enabled: canRedo,
              onTap: onRedo,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
