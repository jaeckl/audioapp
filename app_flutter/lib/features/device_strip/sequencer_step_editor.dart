import 'package:flutter/material.dart';

/// Compact step bar editor for the step sequencer modulator.
/// Displays vertical bars whose heights reflect step values [0, 1].
/// Tap/drag on a bar to adjust.
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

  static const double barHeight = 28.0;
  static const double numberLabelHeight = 14.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: barHeight + 2 + numberLabelHeight,
      child: Column(
        children: [
          // Step bars
          SizedBox(
            height: barHeight,
            child: Row(
              children: List.generate(stepCount, (i) {
                return Expanded(
                  child: GestureDetector(
                    onPanDown: (d) =>
                        _onDrag(d.localPosition.dy, barHeight, i),
                    onPanUpdate: (d) =>
                        _onDrag(d.localPosition.dy, barHeight, i),
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
                            height: (stepValues.length > i ? stepValues[i] : 0.5) *
                                barHeight,
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
          Row(
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
        ],
      ),
    );
  }

  void _onDrag(double dy, double height, int index) {
    final value = (1.0 - (dy / height)).clamp(0.0, 1.0);
    onStepChanged(index, value);
  }
}