import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/device_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'eq_preview.dart';
import 'filter_preview.dart';
import 'panels/compact_fx_layout.dart';
import 'panels/filter_mode_selector.dart';
import 'panels/filter_section_layout.dart';
import 'panels/filter_mode_icons.dart';
import 'rotary_knob.dart';
import 'value_drag_box.dart';

part 'frequency_fx_panels_filter_device_panel.dart';
part 'frequency_fx_panels_filter_device_strip.dart';
part 'frequency_fx_panels_four_band_eq_device_panel.dart';
part 'frequency_fx_panels_four_band_eq_device_strip.dart';
part 'frequency_fx_panels_freq_shifter_device_panel.dart';
part 'frequency_fx_panels_freq_shifter_device_strip.dart';
part 'frequency_fx_panels_private_placeholder_preview_painter.dart';
// ─── File scope note (SRP 400-LOC exception) ─────────────────────────────────
//
// This file holds 6 widgets (3 panels + 3 strip wrappers) plus the shared
// knob wrapper, the filter-mode icon-button row, and the EQ band column
// helpers used by the 4-band EQ. The 400-LOC hard review trigger is exceeded
// because the WP-6 contract (`docs/features/fx-frequency-suite/06-vertical-work-packages.md`)
// explicitly mandates a single file for the panel family — splitting them
// would scatter the device family across files and force WP-7 to import from
// multiple paths for the device-strip routing.
//
// Layout (post-amendment #2):
//   - Filter      : mode-icon row + 2 knobs (cutoff, resonance), centered.
//   - 4-band EQ   : preview + 4 columns × 3 ValueDragBox rows
//                   (freq / gain / Q, reusing the PM synth ratio box pattern).
//   - Ring Mod    : unchanged — single Shift knob.

typedef FrequencyFxParameterChanged = void Function(
    String parameterId, double value);
typedef FrequencyFxModulationAssign = void Function(
    String paramId, double amount)?;

const double _freqFxKnobRowGap = 10;
const double _freqFxColumnGap = 6;

// ─── Shared formatting helpers ────────────────────────────────────────────────

String _formatHz(double hz) {
  if (hz >= 10000) return '${(hz / 1000).toStringAsFixed(1)} kHz';
  if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(2)} kHz';
  return '${hz.round()} Hz';
}

String _formatDb(double db) {
  final rounded = db.toStringAsFixed(1);
  if (db >= 0) return '+$rounded dB';
  return '$rounded dB';
}

String _formatQ(double q) => q.toStringAsFixed(2);

// ─── Engine-side mapping helpers (mirrors `audioapp` normalized→real funcs) ─

double _normalizedToFrequency(double n) {
  final clamped = n.clamp(0.0, 1.0);
  return 20.0 * math.pow(1000.0, clamped);
}

double _normalizedToQ(double n) => 0.1 + n.clamp(0.0, 1.0) * 19.9;

double _normalizedToDb(double n) => -24.0 + n.clamp(0.0, 1.0) * 48.0;

// ─── Shared knob wrapper + layout helpers ─────────────────────────────────────

class _FrequencyFxKnob extends StatelessWidget {
  const _FrequencyFxKnob({
    required this.label,
    required this.value,
    required this.paramId,
    required this.accent,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeLfoId,
    required this.onModulationAssign,
    required this.automationLinkActive,
    required this.onAutomationLinkTap,
    required this.onAutomateParameter,
    this.displayValue,
  });

  final String label;
  final double value;
  final String paramId;
  final Color accent;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final String? displayValue;
  final double size = DeviceStripMetrics.dynamicsFxKnobSize;

  @override
  Widget build(BuildContext context) {
    return RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: size,
      displayValue: displayValue,
      accentColor: accent,
      modulationActive: modulatedParams.contains(paramId),
      automationActive: automatedParams.contains(paramId),
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
      connectModeActive: connectModeLfoId != null,
      onModulationAssign: onModulationAssign != null
          ? (amount) => onModulationAssign!(paramId, amount)
          : null,
      linkModeActive: automationLinkActive,
      onLinkTap: onAutomationLinkTap != null
          ? () => onAutomationLinkTap!(paramId)
          : null,
      onAutomateRequest: onAutomateParameter != null
          ? () => onAutomateParameter!(paramId)
          : null,
      onChanged: (v) => onParameterChanged(paramId, v),
    );
  }
}

_FrequencyFxKnob _knob({
  required String label,
  required double value,
  required String paramId,
  required Color accent,
  required FrequencyFxParameterChanged onParameterChanged,
  required Set<String> modulatedParams,
  required Set<String> automatedParams,
  required Map<String, double> modulationAmounts,
  required int? connectModeLfoId,
  required FrequencyFxModulationAssign onModulationAssign,
  required bool automationLinkActive,
  required ValueChanged<String>? onAutomationLinkTap,
  required ValueChanged<String>? onAutomateParameter,
  String? displayValue,
}) {
  return _FrequencyFxKnob(
    label: label,
    value: value,
    paramId: paramId,
    accent: accent,
    onParameterChanged: onParameterChanged,
    modulatedParams: modulatedParams,
    automatedParams: automatedParams,
    modulationAmounts: modulationAmounts,
    connectModeLfoId: connectModeLfoId,
    onModulationAssign: onModulationAssign,
    automationLinkActive: automationLinkActive,
    onAutomationLinkTap: onAutomationLinkTap,
    onAutomateParameter: onAutomateParameter,
    displayValue: displayValue,
  );
}

Widget _freqFxSinglePage({
  Widget? preview,
  Widget? header,
  required List<Widget> rows,
}) {
  return CompactFxPage(
    preview: preview,
    header: header,
    rows: rows,
    knobRowGap: _freqFxKnobRowGap,
  );
}

// ─── Filter device ────────────────────────────────────────────────────────────

// ─── 4-band EQ device ────────────────────────────────────────────────────────

// ─── Frequency shifter (Ring Mod) device ──────────────────────────────────────

Widget _previewPlaceholder(IconData icon, String label, Color accent) {
  return CustomPaint(
    painter: _PlaceholderPreviewPainter(accent: accent),
    child: Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    ),
  );
}

// Reads the (Freq, Gain, Q) normalized values for a given EQ band off a
// `FourBandEqDeviceSnapshot`. Uses an explicit switch (rather than index
// access) so the analyzer can verify every field name against the snapshot.
(double, double, double) _readBandTriplet(
    FourBandEqDeviceSnapshot dev, int bandIndex) {
  switch (bandIndex) {
    case 1:
      return (dev.ffxBand1Freq, dev.ffxBand1Gain, dev.ffxBand1Q);
    case 2:
      return (dev.ffxBand2Freq, dev.ffxBand2Gain, dev.ffxBand2Q);
    case 3:
      return (dev.ffxBand3Freq, dev.ffxBand3Gain, dev.ffxBand3Q);
    case 4:
      return (dev.ffxBand4Freq, dev.ffxBand4Gain, dev.ffxBand4Q);
    default:
      return (0.5, 0.5, 0.5);
  }
}
