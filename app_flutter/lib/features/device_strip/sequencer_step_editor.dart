import 'package:flutter/material.dart';

/// Compact step bar editor for the step sequencer modulator.
/// Displays vertical bars whose heights reflect step values [0, 1].
/// Tap/drag on a bar to adjust. Fills the height given by its parent.
class SequencerStepEditor extends StatelessWidget {
  const SequencerStepEditor({
    super.key,
    required this.stepValues,
    required this.stepCount,
    required this.onStepChanged,
    this.currentStep,
  });

  final List<double> stepValues;
  final int stepCount;
  final void Function(int index, double value) onStepChanged;
  final int? currentStep;

  static const double _barMinHeight = 28.0;
  static const double numberLabelHeight = 14.0;

  @override
  Widget build(BuildContext context) {
    // Bar area fills all height above the small number-label strip.
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalH = constraints.maxHeight;
        debugPrint('SEQUENCER STEP EDITOR build: totalH=$totalH '
            'stepCount=$stepCount stepValues.len=${stepValues.length}');
        if (totalH <= 0 || !totalH.isFinite) {
          return const SizedBox.shrink();
        }
        final usable = totalH - 2 - numberLabelHeight;
        final barH = usable < _barMinHeight ? _barMinHeight : usable;
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Step bars — fill available vertical space.
            SizedBox(
              height: barH,
              child: Row(
                children: List.generate(stepCount, (i) {
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (d) => _onDrag(d.localPosition.dy, barH, i),
                      onPanUpdate: (d) => _onDrag(d.localPosition.dy, barH, i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Column(
                          children: [
                            const Spacer(),
                            Container(
                              height: (stepValues.length > i ? stepValues[i] : 0.5) * barH,
                              decoration: BoxDecoration(
                                color: currentStep == i
                                    ? const Color(0xFF4BC8E8)
                                    : const Color(0xFFE8A54B),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 2),
            // Number labels below bars
            SizedBox(
              height: numberLabelHeight,
              child: Row(
                children: List.generate(stepCount, (i) {
                  return Expanded(
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: currentStep == i ? Colors.white70 : Colors.white38,
                        fontSize: 8,
                        fontWeight:
                            currentStep == i ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onDrag(double dy, double height, int index) {
    final value = (1.0 - (dy / height)).clamp(0.0, 1.0);
    onStepChanged(index, value);
  }
}