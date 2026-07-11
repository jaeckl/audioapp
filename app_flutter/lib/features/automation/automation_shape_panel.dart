import 'package:flutter/material.dart';

import 'automation_curve_shapes.dart';
import 'automation_editor_theme.dart';
import 'automation_shape_icon.dart';

part 'automation_shape_panel_shape_chip.dart';
part 'automation_shape_panel_shape_slider.dart';

/// Shape insert panel — shown only when inserting between two anchors.
class AutomationShapePanel extends StatelessWidget {
  const AutomationShapePanel({
    super.key,
    required this.activeShape,
    required this.params,
    required this.onShapeSelected,
    required this.onParamsChanged,
    required this.onClose,
  });

  final AutomationCurveShape? activeShape;
  final AutomationShapeParams params;
  final ValueChanged<AutomationCurveShape> onShapeSelected;
  final ValueChanged<AutomationShapeParams> onParamsChanged;
  final VoidCallback onClose;

  static const _shapes = AutomationCurveShape.values;

  @override
  Widget build(BuildContext context) {
    final accent = AutomationEditorTheme.accent;
    final showPeriodic = activeShape?.isPeriodic ?? false;
    final showDuty = activeShape?.usesDuty ?? false;

    return ColoredBox(
      color: AutomationEditorTheme.panelBackground,
      child: SizedBox(
        height: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Text(
                    'Insert shape',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AutomationEditorTheme.labelMuted,
                    onPressed: onClose,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _shapes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final shape = _shapes[index];
                  final selected = activeShape == shape;
                  return _ShapeChip(
                    shape: shape,
                    selected: selected,
                    accent: accent,
                    onTap: () => onShapeSelected(shape),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  if (activeShape == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Pick a shape to replace the segment between your two points.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  _ShapeSlider(
                    label: 'Floor',
                    value: params.min,
                    onChanged: activeShape == null
                        ? null
                        : (v) => onParamsChanged(params.copyWith(min: v)),
                  ),
                  _ShapeSlider(
                    label: 'Peak',
                    value: params.max,
                    onChanged: activeShape == null
                        ? null
                        : (v) => onParamsChanged(params.copyWith(max: v)),
                  ),
                  if (showPeriodic) ...[
                    _ShapeSlider(
                      label: 'Cycles',
                      value: params.cycles,
                      min: 0.25,
                      max: 16,
                      divisions: 63,
                      display: params.cycles.toStringAsFixed(2),
                      onChanged: (v) =>
                          onParamsChanged(params.copyWith(cycles: v)),
                    ),
                    _ShapeSlider(
                      label: 'Phase',
                      value: params.phase,
                      display: '${(params.phase * 100).round()}%',
                      onChanged: (v) =>
                          onParamsChanged(params.copyWith(phase: v)),
                    ),
                  ],
                  if (showDuty)
                    _ShapeSlider(
                      label: 'Pulse width',
                      value: params.duty,
                      min: 0.05,
                      max: 0.95,
                      display: '${(params.duty * 100).round()}%',
                      onChanged: (v) =>
                          onParamsChanged(params.copyWith(duty: v)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
