import 'package:flutter/material.dart';

import 'automation_curve_shapes.dart';
import 'automation_editor_theme.dart';
import 'automation_shape_icon.dart';

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
                      onChanged: (v) => onParamsChanged(params.copyWith(cycles: v)),
                    ),
                    _ShapeSlider(
                      label: 'Phase',
                      value: params.phase,
                      display: '${(params.phase * 100).round()}%',
                      onChanged: (v) => onParamsChanged(params.copyWith(phase: v)),
                    ),
                  ],
                  if (showDuty)
                    _ShapeSlider(
                      label: 'Pulse width',
                      value: params.duty,
                      min: 0.05,
                      max: 0.95,
                      display: '${(params.duty * 100).round()}%',
                      onChanged: (v) => onParamsChanged(params.copyWith(duty: v)),
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

class _ShapeChip extends StatelessWidget {
  const _ShapeChip({
    required this.shape,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final AutomationCurveShape shape;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? accent : Colors.white.withValues(alpha: 0.72);

    return Tooltip(
      message: shape.accessibilityLabel,
      child: Semantics(
        button: true,
        selected: selected,
        label: shape.accessibilityLabel,
        child: Material(
          color: selected ? accent.withValues(alpha: 0.22) : const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? accent : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: AutomationShapeIcon(shape: shape, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeSlider extends StatelessWidget {
  const _ShapeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions = 100,
    this.display,
  });

  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int divisions;
  final String? display;

  @override
  Widget build(BuildContext context) {
    final accent = AutomationEditorTheme.accent;
    final shown = display ?? value.toStringAsFixed(2);
    final enabled = onChanged != null;

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: enabled ? 0.6 : 0.3),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            shown,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Colors.white.withValues(alpha: enabled ? 0.75 : 0.35),
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
