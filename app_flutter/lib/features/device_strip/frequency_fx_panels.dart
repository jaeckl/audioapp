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

typedef FrequencyFxParameterChanged = void Function(String parameterId, double value);
typedef FrequencyFxModulationAssign = void Function(String paramId, double amount)?;

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

class FilterDevicePanel extends StatelessWidget {
  const FilterDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFF5BC0EB);
  static const containerTabs = <DeviceTabSpec>[];

  /// Filter device — compact dynamics-FX-sized card.
  static const double designWidth = 216;

  final FilterDeviceSnapshot device;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final cutoffNorm = device.ffxCutoff.clamp(0.0, 1.0);
    final resNorm = device.ffxResonance.clamp(0.0, 1.0);
    final modeNorm = device.ffxFilterMode.clamp(0.0, 1.0);
    final cutoffHz = _normalizedToFrequency(cutoffNorm);
    final q = _normalizedToQ(resNorm);
    // 4 modes quantised onto [0,1] at 0.125 / 0.375 / 0.625 / 0.875.
    final modeIndex = (modeNorm * 4.0).round().clamp(0, 3);
    final previewMode = FilterPreviewMode.values[modeIndex];

    return FilterSectionLayout(
      preview: FilterPreview(
        cutoffHz: cutoffHz,
        q: q,
        mode: previewMode,
        accent: accent,
      ),
      modeSelector: FilterModeSelector(
        selectedIndex: modeIndex,
        accentColor: accent,
        modulated: modulatedParams.contains('ffxFilterMode'),
        automated: automatedParams.contains('ffxFilterMode'),
        onSelected: (index) => onParameterChanged(
          'ffxFilterMode',
          FilterFxModeNorm.values[index],
        ),
      ),
      controls: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _knob(
              label: 'Cutoff',
              value: cutoffNorm,
              paramId: 'ffxCutoff',
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
              displayValue: _formatHz(cutoffHz),
            ),
            const SizedBox(width: DeviceStripMetrics.dynamicsFxKnobGap),
            _knob(
              label: 'Resonance',
              value: resNorm,
              paramId: 'ffxResonance',
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
              displayValue: _formatQ(q),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterDeviceStrip extends StatelessWidget {
  const FilterDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final FilterDeviceSnapshot device;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) => FilterDevicePanel(
        device: device,
        onParameterChanged: onParameterChanged,
        modulatedParams: modulatedParams,
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      );
}

// ─── 4-band EQ device ────────────────────────────────────────────────────────

class FourBandEqDevicePanel extends StatelessWidget {
  const FourBandEqDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFF78C091);
  static const containerTabs = <DeviceTabSpec>[];

  /// 4-band EQ — compact card.
  static const double designWidth = 216;

  final FourBandEqDeviceSnapshot device;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final previewBands = _buildPreviewBands(device);
    return _freqFxSinglePage(
      preview: FourBandEqPreview(bands: previewBands, accent: accent),
      rows: [
        _buildBandColumnsGrid(context, device),
      ],
    );
  }

  List<EqBand> _buildPreviewBands(FourBandEqDeviceSnapshot dev) => [
        EqBand(
          cutoffHz: _normalizedToFrequency(dev.ffxBand1Freq.clamp(0.0, 1.0)),
          gainDb: _normalizedToDb(dev.ffxBand1Gain.clamp(0.0, 1.0)),
          q: _normalizedToQ(dev.ffxBand1Q.clamp(0.0, 1.0)),
          isShelf: true,
        ),
        EqBand(
          cutoffHz: _normalizedToFrequency(dev.ffxBand2Freq.clamp(0.0, 1.0)),
          gainDb: _normalizedToDb(dev.ffxBand2Gain.clamp(0.0, 1.0)),
          q: _normalizedToQ(dev.ffxBand2Q.clamp(0.0, 1.0)),
          isShelf: false,
        ),
        EqBand(
          cutoffHz: _normalizedToFrequency(dev.ffxBand3Freq.clamp(0.0, 1.0)),
          gainDb: _normalizedToDb(dev.ffxBand3Gain.clamp(0.0, 1.0)),
          q: _normalizedToQ(dev.ffxBand3Q.clamp(0.0, 1.0)),
          isShelf: false,
        ),
        EqBand(
          cutoffHz: _normalizedToFrequency(dev.ffxBand4Freq.clamp(0.0, 1.0)),
          gainDb: _normalizedToDb(dev.ffxBand4Gain.clamp(0.0, 1.0)),
          q: _normalizedToQ(dev.ffxBand4Q.clamp(0.0, 1.0)),
          isShelf: true,
        ),
      ];

  /// Renders the 4 EQ bands as 4 columns side-by-side. Each column has a
  /// header label and 3 stacked `ValueDragBox`es (FREQ / GAIN / Q) — the
  /// same compact shape as the Phase-Mod synth `Ratio` chip.
  Widget _buildBandColumnsGrid(
      BuildContext context, FourBandEqDeviceSnapshot dev) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var bandIndex = 1; bandIndex <= 4; bandIndex++) ...[
          if (bandIndex > 1) const SizedBox(width: _freqFxColumnGap),
          Expanded(child: _buildBandColumn(context, dev, bandIndex: bandIndex)),
        ],
      ],
    );
  }

  Widget _buildBandColumn(BuildContext context, FourBandEqDeviceSnapshot dev,
      {required int bandIndex}) {
    final (freqNorm, gainNorm, qNorm) = _readBandTriplet(dev, bandIndex);
    final freqId = 'ffxBand' '$bandIndex' 'Freq';
    final gainId = 'ffxBand' '$bandIndex' 'Gain';
    final qId = 'ffxBand' '$bandIndex' 'Q';
    final bandLabel = _bandLabel(bandIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Column header (band label)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            bandLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              height: 1.05,
            ),
          ),
        ),
        // FREQ row — drag/scroll changes freq; double-tap resets to neutral
        // (centre of the log-frequency range, i.e. ≈ 1 kHz at norm 0.5).
        ValueDragBox(
          valueNorm: freqNorm,
          // Quantised to log-spaced frequencies across the audible range.
          // The values are display strings only — the panel's `onChanged`
          // converts the index back to `[0,1]` and the engine converts to Hz.
          values: const [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
          format: (n) => _formatHz(_normalizedToFrequency(n)),
          accent: accent,
          paramId: freqId,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          onChanged: (v) => onParameterChanged(freqId, v),
          resetIndex: 5, // ~ 1 kHz
          dragPixelsPerStep: 14,
          footerLabel: 'FREQ',
        ),
        const SizedBox(height: 4),
        // GAIN row — discrete gain steps in dB. Double-tap resets to 0 dB
        // (neutral, idx 4 of the 9 steps centred on 0 dB).
        ValueDragBox(
          valueNorm: gainNorm,
          values: const [-24.0, -18.0, -12.0, -6.0, 0.0, 6.0, 12.0, 18.0, 24.0],
          // Display uses _formatDb for consistency, but values are absolute dB.
          format: (n) => _formatDb(_normalizedToDb(n)),
          accent: accent,
          paramId: gainId,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          onChanged: (v) => onParameterChanged(gainId, v),
          resetIndex: 4, // 0 dB
          dragPixelsPerStep: 14,
          footerLabel: 'GAIN',
        ),
        const SizedBox(height: 4),
        // Q row — discrete Q values from 0.1 to 20.0.
        ValueDragBox(
          valueNorm: qNorm,
          values: const [
            0.10, 0.25, 0.50, 0.71, 1.00, 1.41, 2.00, 4.00, 8.00, 20.00
          ],
          // Display uses _formatQ for consistency, but values are absolute Q.
          format: (n) => _formatQ(_normalizedToQ(n)),
          accent: accent,
          paramId: qId,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          onChanged: (v) => onParameterChanged(qId, v),
          resetIndex: 3, // Q ≈ 0.71 (Butterworth)
          dragPixelsPerStep: 14,
          footerLabel: 'Q',
        ),
      ],
    );
  }

  static String _bandLabel(int bandIndex) {
    switch (bandIndex) {
      case 1:
        return 'LOW SHELF';
      case 2:
        return 'LOW MID';
      case 3:
        return 'HIGH MID';
      case 4:
        return 'HIGH SHELF';
      default:
        return '';
    }
  }
}

class FourBandEqDeviceStrip extends StatelessWidget {
  const FourBandEqDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final FourBandEqDeviceSnapshot device;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) => FourBandEqDevicePanel(
        device: device,
        onParameterChanged: onParameterChanged,
        modulatedParams: modulatedParams,
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      );
}

// ─── Frequency shifter (Ring Mod) device ──────────────────────────────────────

class FreqShifterDevicePanel extends StatelessWidget {
  const FreqShifterDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFFC77DFF);
  static const containerTabs = <DeviceTabSpec>[];

  /// Ring mod / frequency shifter — compact card.
  static const double designWidth = 216;

  final FrequencyShifterDeviceSnapshot device;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final shiftNorm = device.ffxShift.clamp(0.0, 1.0);
    final shiftHz = (shiftNorm - 0.5) * 4000.0;

    return _freqFxSinglePage(
      preview: _previewPlaceholder(
        Icons.swap_horiz,
        'Shifted Spectrum',
        accent,
      ),
      rows: [
        Center(
          child: _knob(
            label: 'Shift',
            value: shiftNorm,
            paramId: 'ffxShift',
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
            displayValue: shiftHz >= 0
                ? '+${shiftHz.toStringAsFixed(0)} Hz'
                : '${shiftHz.toStringAsFixed(0)} Hz',
          ),
        ),
      ],
    );
  }
}

class FreqShifterDeviceStrip extends StatelessWidget {
  const FreqShifterDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final FrequencyShifterDeviceSnapshot device;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) => FreqShifterDevicePanel(
        device: device,
        onParameterChanged: onParameterChanged,
        modulatedParams: modulatedParams,
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      );
}

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

class _PlaceholderPreviewPainter extends CustomPainter {
  _PlaceholderPreviewPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0E0E14),
    );
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var x = 0.0; x <= size.width; x += 2) {
      final t = x / size.width;
      final y = size.height * 0.5 +
          math.sin(t * math.pi * 4 + 1.2) * size.height * 0.18 +
          math.sin(t * math.pi * 11) * size.height * 0.04;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlaceholderPreviewPainter old) =>
      old.accent != accent;
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