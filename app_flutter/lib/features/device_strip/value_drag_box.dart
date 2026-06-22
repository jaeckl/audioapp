import 'package:flutter/material.dart';

import 'device_automation_spinner.dart';
import 'modulator_polarity.dart';

/// Reusable compact value-drag box.
///
/// Originally extracted from the Phase-Mod synth `Ratio` chip — a 44×26 box
/// that shows a single value, supports vertical drag to step through a list
/// of quantised values, and double-tap to reset to a "neutral" index.
///
/// Wraps [deviceAutomationSpinner] so it integrates with the LFO connect
/// mode, modulation, and automation-link flows. Used by:
///
///   - PM synth `Ratio` (one per operator)
///   - 4-band EQ `Freq` / `Gain` / `Q` (one per band)
///   - Filter mode (one row of 4 buttons)
///
/// The values list is quantised: vertical drag converts pixel delta to a
/// number of indices to step, clamped to `[0, values.length - 1]`. The
/// normalised value sent via [onChanged] is the index mapped back to the
/// `[0, 1]` range. The engine-side mapping (e.g. log-frequency for EQ
/// bands) lives in the `setParameter` clamp + `_normalizedToX` helpers
/// of the consumer panel.
class ValueDragBox extends StatelessWidget {
  const ValueDragBox({
    super.key,
    required this.valueNorm,
    required this.values,
    required this.format,
    required this.accent,
    required this.paramId,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeLfoId,
    required this.onModulationAssign,
    required this.automationLinkActive,
    required this.onAutomationLinkTap,
    required this.onAutomateParameter,
    required this.onChanged,
    this.resetIndex = 0,
    this.dragPixelsPerStep = 12,
    this.borderAlpha = 0.4,
    this.width = 44,
    this.height = 26,
    this.showFooterLabel = true,
    this.footerLabel = '',
  });

  /// Current normalised `[0, 1]` value; will be quantised via [values].
  final double valueNorm;

  /// Quantised value list. The visible index is `valueNorm * (values.length-1)`
  /// rounded to the nearest integer and clamped to `[0, values.length-1]`.
  /// When the user drags, the index changes by one step per
  /// [dragPixelsPerStep] pixels of vertical motion (drag up = increase).
  final List<double> values;

  /// Formats the current value (in `[0, 1]` normalised space) to a string
  /// for display in the box.
  final String Function(double norm) format;

  final Color accent;
  final String paramId;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final ValueChanged<double> onChanged;

  /// Index used when the user double-taps the box. Defaults to 0.
  final int resetIndex;

  /// Pixel sensitivity for the vertical drag.
  final double dragPixelsPerStep;

  final double borderAlpha;
  final double width;
  final double height;

  /// Whether to render the small footer label below the box.
  final bool showFooterLabel;
  final String footerLabel;

  /// Maps a normalised value to the nearest quantised index.
  static int normToIndex(double norm, int valueCount) {
    if (valueCount <= 1) return 0;
    final clamped = norm.clamp(0.0, 1.0);
    final raw = clamped * (valueCount - 1);
    final rounded = raw.round();
    return rounded.clamp(0, valueCount - 1);
  }

  /// Maps a quantised index to a normalised value in `[0, 1]`.
  static double indexToNorm(int index, int valueCount) {
    if (valueCount <= 1) return 0.0;
    final clamped = index.clamp(0, valueCount - 1);
    return clamped / (valueCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    final valueCount = values.length;
    final idx = normToIndex(valueNorm, valueCount);
    final display = format(valueNorm);

    double dragStartY = 0;
    int dragStartIdx = idx;

    final inner = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (d) {
        dragStartY = d.localPosition.dy;
        dragStartIdx = idx;
      },
      onVerticalDragUpdate: (d) {
        final delta = ((dragStartY - d.localPosition.dy) / dragPixelsPerStep).round();
        final nextIdx = (dragStartIdx + delta).clamp(0, valueCount - 1);
        if (nextIdx != idx) {
          onChanged(indexToNorm(nextIdx, valueCount));
        }
      },
      onDoubleTap: () => onChanged(indexToNorm(resetIndex, valueCount)),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Text(
          display,
          style: TextStyle(
            color: accent,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        deviceAutomationSpinner(
          paramId: paramId,
          width: width,
          height: height,
          accentColor: accent,
          borderAlpha: borderAlpha,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          modulatorPolarity: ModulatorPolarity.bipolar,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          child: inner,
        ),
        if (showFooterLabel) ...[
          const SizedBox(height: 2),
          Text(
            footerLabel,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}