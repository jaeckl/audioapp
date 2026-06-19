import 'package:flutter/material.dart';

import 'automation_editor_metrics.dart';
import 'automation_editor_theme.dart';

/// Fixed left column showing automation value scale (replaces piano keys).
class AutomationValueColumn extends StatelessWidget {
  const AutomationValueColumn({super.key, required this.valueAxisHeight});

  final double valueAxisHeight;

  static const _labels = ['100', '75', '50', '25', '0'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AutomationEditorMetrics.valueColumnWidth,
      height: valueAxisHeight,
      child: ColoredBox(
        color: AutomationEditorTheme.valueColumnBackground,
        child: Stack(
          children: [
            for (var i = 0; i < _labels.length; i++)
              Positioned(
                left: 0,
                right: 0,
                top: AutomationEditorMetrics.dyFromValue(
                      1.0 - i / (_labels.length - 1),
                      valueAxisHeight,
                    ) -
                    8,
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AutomationEditorTheme.labelMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
