import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_automation_spinner.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'sampler_envelope_preview.dart';

enum BassPanelDensity { strip, editor }

enum BassSynthDeviceTab { tone, filter }

class BassSynthDevicePanel extends StatefulWidget {
  const BassSynthDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.density = BassPanelDensity.strip,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final BassSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final BassPanelDensity density;
  final BassSynthDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const Color accent = DeviceStripTheme.bassSynthAccent;

  /// Design width for this panel's two-column tab layout.
  static const double designWidth = 440;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'TONE', icon: Icons.tune),
    DeviceTabSpec(label: 'FILTER', icon: Icons.filter_alt),
  ];

  static String subOctaveLabel(int value) {
    return switch (value) {
      0 => '-1',
      1 => '-2',
      2 => '-3',
      _ => '$value',
    };
  }

  static String bassOctaveLabel(int value) {
    return switch (value) {
      0 => '-4',
      1 => '-3',
      2 => '-2',
      3 => '-1',
      4 => '0',
      _ => '$value',
    };
  }

  @override
  State<BassSynthDevicePanel> createState() => _BassSynthDevicePanelState();
}

class _BassSynthDevicePanelState extends State<BassSynthDevicePanel> {
  late BassSynthDeviceTab _tab;
  double _octDragStartY = 0;
  int _octDragStartValue = 0;

  BassSynthDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _knobSize => widget.density == BassPanelDensity.editor
      ? DeviceKnobSizes.editor
      : DeviceKnobSizes.strip;

  Widget _knob({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    String? displayValue,
    double? size,
    String? paramId,
    Map<String, double> modulationAmounts = const {},
    int? connectModeLfoId,
    void Function(String paramId, double amount)? onModulationAssign,
    double labelGap = 3,
  }) {
    final modAmount = paramId != null ? modulationAmounts[paramId] ?? 0.0 : 0.0;
    return RotaryKnob(
      label: label,
      value: value,
      onChanged: onChanged,
      displayValue: displayValue,
      size: size ?? _knobSize,
      labelGap: labelGap,
      accentColor: BassSynthDevicePanel.accent,
      modulationActive: paramId != null && widget.modulatedParams.contains(paramId),
      automationActive: paramId != null && widget.automatedParams.contains(paramId),
      modulationAmount: modAmount,
      connectModeActive: paramId != null && connectModeLfoId != null,
      onModulationAssign: paramId != null && onModulationAssign != null
          ? (a) => onModulationAssign(paramId, a)
          : null,
      linkModeActive: paramId != null && widget.automationLinkActive,
      linkModeAccent: const Color(0xFFB48CFF),
      onLinkTap: paramId != null && widget.onAutomationLinkTap != null
          ? () => widget.onAutomationLinkTap!(paramId)
          : null,
      onAutomateRequest: paramId != null && widget.onAutomateParameter != null
          ? () => widget.onAutomateParameter!(paramId)
          : null,
    );
  }

  Widget _panelBox({
    required Widget child,
    Color color = const Color(0xFF121218),
    bool showBorder = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(4),
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: showBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }

  /// Section label like "OSCILLATOR" or "AMP"
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tab = BassSynthDeviceTab.tone;
  }

  @override
  void didUpdateWidget(covariant BassSynthDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null && widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildTabContent();
    return body;
  }

  Widget _buildTabContent() {
    return switch (_activeTab) {
      BassSynthDeviceTab.tone => _toneTab(),
      BassSynthDeviceTab.filter => _filterTab(),
    };
  }

  // ── TONE TAB ──────────────────────────────────────────────
  //
  // Layout: Row with two columns
  //   LEFT  — OSCILLATOR (knob row) + AMP (env preview + A/S/R) stacked
  //   RIGHT — PERFORMANCE column (Glide + Vel stacked vertically)
  Widget _toneTab() {
    final kSize = _knobSize;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── LEFT column: Oscillator + Amp ──
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('OSCILLATOR'),
                  Expanded(
                    flex: 5,
                    child: _panelBox(
                      color: const Color(0xFF16161E),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _knob(label: 'Morph', value: widget.device.bassOscShape, size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(widget.device.bassOscShape),
                            onChanged: (v) => widget.onParameterChanged('bassOscShape', v),
                            paramId: 'bassOscShape',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _knob(label: 'Sub Mix', value: widget.device.bassSubMix, size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(widget.device.bassSubMix),
                            onChanged: (v) => widget.onParameterChanged('bassSubMix', v),
                            paramId: 'bassSubMix',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _intOctaveSlot(value: widget.device.bassSubOctave, paramId: 'bassSubOctave',
                            min: 0, max: 2, label: 'Sub',
                            formatter: BassSynthDevicePanel.subOctaveLabel,
                          ),
                          _intOctaveSlot(value: widget.device.bassOctave, paramId: 'bassOctave',
                            min: 0, max: 4, label: 'Oct',
                            formatter: BassSynthDevicePanel.bassOctaveLabel,
                          ),
                          _knob(label: 'Noise', value: widget.device.bassNoise, size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(widget.device.bassNoise),
                            onChanged: (v) => widget.onParameterChanged('bassNoise', v),
                            paramId: 'bassNoise',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _sectionLabel('AMP'),
                  Expanded(
                    flex: 4,
                    child: _panelBox(
                      color: const Color(0xFF1A1A24),
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                      child: Row(
                        children: [
                          Expanded(flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(2, 2, 6, 2),
                              child: _ampEnvelopePreview(),
                            ),
                          ),
                          Expanded(flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _knob(label: 'A', value: widget.device.attack, size: kSize,
                                    labelGap: 0,
                                    displayValue: SamplerDevicePanel.formatPercent(widget.device.attack),
                                    onChanged: (v) => widget.onParameterChanged('attack', v),
                                    paramId: 'attack',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign: widget.onModulationAssign,
                                  ),
                                  _knob(label: 'S', value: widget.device.sustain, size: kSize,
                                    labelGap: 0,
                                    displayValue: SamplerDevicePanel.formatPercent(widget.device.sustain),
                                    onChanged: (v) => widget.onParameterChanged('sustain', v),
                                    paramId: 'sustain',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign: widget.onModulationAssign,
                                  ),
                                  _knob(label: 'R', value: widget.device.release, size: kSize,
                                    labelGap: 0,
                                    displayValue: SamplerDevicePanel.formatPercent(widget.device.release),
                                    onChanged: (v) => widget.onParameterChanged('release', v),
                                    paramId: 'release',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign: widget.onModulationAssign,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── RIGHT column: PERFORMANCE (Glide + Vel) ──
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('PERFORMANCE'),
                Expanded(
                  child: _panelBox(
                    color: const Color(0xFF16161E),
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _knob(label: 'Glide', value: widget.device.glideMs, size: kSize,
                          displayValue: widget.device.glideMs <= 0.001
                              ? 'Off'
                              : '${(widget.device.glideMs * 2000).round()} ms',
                          onChanged: (v) => widget.onParameterChanged('glideMs', v),
                          paramId: 'glideMs',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                        const SizedBox(height: 12),
                        _knob(label: 'Vel', value: widget.device.bassVelocitySense, size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.bassVelocitySense),
                          onChanged: (v) => widget.onParameterChanged('bassVelocitySense', v),
                          paramId: 'bassVelocitySense',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Amp envelope shape preview for the TONE tab.
  Widget _ampEnvelopePreview() {
    return SamplerEnvelopePreview(
      attack: widget.device.attack,
      decay: widget.device.attack * 0.3 + 0.02, // decay ~related to attack feel
      sustain: widget.device.sustain,
      release: widget.device.release,
      accent: BassSynthDevicePanel.accent,
      label: 'AMP',
    );
  }

  // ── FILTER TAB ──────────────────────────────────────────────
  //
  // Layout: Row with two columns
  //   LEFT  — FILTER CURVE preview + FILTER controls (Cutoff, Res, Env Amt, Decay)
  //   RIGHT — SATURATION column (Drive + Squash stacked vertically)
  Widget _filterTab() {
    final kSize = _knobSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── LEFT column: Filter curve + controls ──
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('FILTER CURVE'),
                  Expanded(
                    flex: 4,
                    child: _panelBox(
                      color: const Color(0xFF16161E),
                      padding: const EdgeInsets.all(2),
                      child: _FilterCurvePreview(
                        cutoff: widget.device.filterCutoff,
                        resonance: widget.device.bassFilterResonance,
                        accent: BassSynthDevicePanel.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _sectionLabel('FILTER'),
                  Expanded(
                    flex: 5,
                    child: _panelBox(
                      color: const Color(0xFF1A1A24),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _knob(label: 'Cutoff', value: widget.device.filterCutoff, size: kSize,
                            displayValue: SamplerDevicePanel.formatCutoffHz(widget.device.filterCutoff),
                            onChanged: (v) => widget.onParameterChanged('filterCutoff', v),
                            paramId: 'filterCutoff',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _knob(label: 'Res', value: widget.device.bassFilterResonance, size: kSize,
                            displayValue: SamplerDevicePanel.formatQ(widget.device.bassFilterResonance),
                            onChanged: (v) => widget.onParameterChanged('bassFilterResonance', v),
                            paramId: 'bassFilterResonance',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _knob(label: 'Env Amt', value: widget.device.filterEnvAmount, size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(widget.device.filterEnvAmount),
                            onChanged: (v) => widget.onParameterChanged('filterEnvAmount', v),
                            paramId: 'filterEnvAmount',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _knob(label: 'Decay', value: widget.device.filterDecay, size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(widget.device.filterDecay),
                            onChanged: (v) => widget.onParameterChanged('filterDecay', v),
                            paramId: 'filterDecay',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── RIGHT column: SATURATION (Drive + Squash) ──
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('SATURATION'),
                Expanded(
                  child: _panelBox(
                    color: const Color(0xFF16161E),
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _knob(label: 'Drive', value: widget.device.bassDrive, size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.bassDrive),
                          onChanged: (v) => widget.onParameterChanged('bassDrive', v),
                          paramId: 'bassDrive',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                        const SizedBox(height: 12),
                        _knob(label: 'Squash', value: widget.device.bassSquash, size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.bassSquash),
                          onChanged: (v) => widget.onParameterChanged('bassSquash', v),
                          paramId: 'bassSquash',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Int octave slot ────────────────────────────────────────
  //
  // Layout exactly mirrors RotaryKnob:
  //   [control body same height as knob SizedBox]
  //   [gap]
  //   [label below with same fontSize/color/weight]
  Widget _intOctaveSlot({
    required int value,
    required String paramId,
    required int min,
    required int max,
    required String label,
    required String Function(int) formatter,
  }) {
    final display = formatter(value);
    final accent = BassSynthDevicePanel.accent;
    final muted = accent.withValues(alpha: 0.55);
    final size = _knobSize;
    // Mirror RotaryKnob: labelSize = size >= 56 ? 10 : 9
    final labelSize = size >= DeviceKnobSizes.strip ? 10.0 : 9.0;

    void bump(int delta) {
      final next = (value + delta).clamp(min, max);
      if (next != value) {
        widget.onParameterChanged(paramId, next.toDouble());
      }
    }

    final inner = Column(
      children: [
        Expanded(
          child: _StepButton(
            icon: Icons.keyboard_arrow_up_rounded,
            color: muted,
            onTap: () => bump(1),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) {
            _octDragStartY = d.localPosition.dy;
            _octDragStartValue = value;
          },
          onVerticalDragUpdate: (d) {
            final delta = ((_octDragStartY - d.localPosition.dy) / 8).round();
            final next = (_octDragStartValue + delta).clamp(min, max);
            if (next != value) {
              widget.onParameterChanged(paramId, next.toDouble());
            }
          },
          onDoubleTap: () => widget.onParameterChanged(paramId, 0.toDouble()),
          child: Text(
            display,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
        Expanded(
          child: _StepButton(
            icon: Icons.keyboard_arrow_down_rounded,
            color: muted,
            onTap: () => bump(-1),
          ),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Spinner shell at size+4 to match RotaryKnob SizedBox height
        deviceAutomationSpinner(
          paramId: paramId,
          width: 46,
          height: size + 4,
          accentColor: accent,
          borderAlpha: 0.35,
          child: inner,
          modulatedParams: widget.modulatedParams,
          automatedParams: widget.automatedParams,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
          automationLinkActive: widget.automationLinkActive,
          onAutomationLinkTap: widget.onAutomationLinkTap,
          onAutomateParameter: widget.onAutomateParameter,
        ),
        const SizedBox(height: 3), // matches RotaryKnob.labelGap default
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Step button for octave int spinner ▲/▼ ─────────────────────
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

// ── Filter curve preview ──────────────────────────────────────
//
// Shows a low-pass filter response with resonance peak at cutoff.
class _FilterCurvePreview extends StatelessWidget {
  const _FilterCurvePreview({
    required this.cutoff,
    required this.resonance,
    required this.accent,
  });

  final double cutoff;
  final double resonance;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FilterCurvePainter(
        cutoff: cutoff,
        resonance: resonance,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _FilterCurvePainter extends CustomPainter {
  _FilterCurvePainter({
    required this.cutoff,
    required this.resonance,
    required this.accent,
  });

  final double cutoff;
  final double resonance;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    const pad = 4.0;
    final plotH = h - pad * 2;
    final plotW = w - pad * 2;

    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0E0E14));

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(pad, y), Offset(w - pad, y), gridPaint);
    }

    // Normalized cutoff position along x-axis (0..1 mapped to log-ish scale)
    final cx = pad + math.min(cutoff, 0.999) * plotW;

    // Draw the filter curve path
    final path = Path();
    final steps = 64;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = pad + t * plotW;

      // Simple LP12 response approximation:
      // - Flat passband (gain ≈ 1) for x < cutoff
      // - 12dB/oct rolloff after cutoff: gain ~ (cutoff/x)^2
      // - Resonance peak at cutoff
      final relCutoff = cutoff.clamp(0.01, 0.999);
      final normFreq = t.clamp(0.001, 0.999);
      final ratio = normFreq / relCutoff;

      // Simple resonant LP response
      final q = 0.5 + resonance * 3.0; // Q range 0.5–3.5
      final peakGain = q > 0.5 ? 1.0 + (q - 0.5) * 0.8 : 1.0;
      double gain;
      if (ratio < 1.0) {
        // Passband — resonance peak at cutoff
        gain = peakGain * (1.0 - (1.0 - ratio) * (1.0 - ratio) * 0.5);
      } else {
        // Rolloff — 12dB/oct ~ (1/ratio)^2
        gain = (1.0 / (ratio * ratio)).clamp(0.0, 1.0);
      }
      gain = gain.clamp(0.0, 1.0);

      final y = pad + plotH - gain * plotH;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw the curve
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Fill under the curve
    final fillPath = Path.from(path)
      ..lineTo(pad + plotW, pad + plotH)
      ..lineTo(pad, pad + plotH)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = accent.withValues(alpha: 0.08),
    );

    // Resonance marker at cutoff position
    if (resonance > 0.05) {
      final peakH = pad + plotH - (1.0 + resonance * 0.4).clamp(0.0, 1.0) * plotH;
      canvas.drawCircle(
        Offset(cx, peakH),
        3,
        Paint()
          ..color = accent
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(cx, peakH),
        5,
        Paint()
          ..color = accent.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Cutoff label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'LP12',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.15),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, const Offset(pad + 4, pad + 3));
  }

  @override
  bool shouldRepaint(covariant _FilterCurvePainter oldDelegate) {
    return oldDelegate.cutoff != cutoff ||
        oldDelegate.resonance != resonance ||
        oldDelegate.accent != accent;
  }
}