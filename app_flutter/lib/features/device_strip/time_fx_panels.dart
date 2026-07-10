import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'panels/compact_fx_layout.dart';
import 'rotary_knob.dart';

typedef TimeFxParameterChanged = void Function(
    String parameterId, double value);
typedef TimeFxModulationAssign = void Function(String paramId, double amount)?;

const double _timeFxKnobRowGap = 10;

String _formatHz(double hz) {
  if (hz >= 10000) {
    return '${(hz / 1000).toStringAsFixed(1)} kHz';
  }
  if (hz >= 1000) {
    return '${(hz / 1000).toStringAsFixed(2)} kHz';
  }
  return '${hz.round()} Hz';
}

class _TimeFxKnob extends StatelessWidget {
  const _TimeFxKnob({
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
    this.labelOptions = const [],
    this.onLabelOptionSelected,
    this.size,
  });

  final String label;
  final double value;
  final String paramId;
  final Color accent;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final String? displayValue;
  final List<String> labelOptions;
  final ValueChanged<String>? onLabelOptionSelected;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: size ?? DeviceStripMetrics.dynamicsFxKnobSize,
      displayValue: displayValue,
      labelOptions: labelOptions,
      onLabelOptionSelected: onLabelOptionSelected,
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

_TimeFxKnob _knob({
  required String label,
  required double value,
  required String paramId,
  required Color accent,
  required TimeFxParameterChanged onParameterChanged,
  required Set<String> modulatedParams,
  required Set<String> automatedParams,
  required Map<String, double> modulationAmounts,
  required int? connectModeLfoId,
  required TimeFxModulationAssign onModulationAssign,
  required bool automationLinkActive,
  required ValueChanged<String>? onAutomationLinkTap,
  required ValueChanged<String>? onAutomateParameter,
  String? displayValue,
  List<String> labelOptions = const [],
  ValueChanged<String>? onLabelOptionSelected,
  double? size,
}) {
  return _TimeFxKnob(
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
    labelOptions: labelOptions,
    onLabelOptionSelected: onLabelOptionSelected,
    size: size,
  );
}

Widget _timeFxSinglePage({
  required List<Widget> rows,
}) {
  return CompactFxPage(rows: rows, knobRowGap: _timeFxKnobRowGap);
}

Widget _knobGridRow(List<_TimeFxKnob?> slots) => compactFxKnobGridRow(slots);

// ── Delay ──────────────────────────────────────────────────────────────────

class DelayFxPanel extends StatelessWidget {
  const DelayFxPanel({
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

  static const accent = Color(0xFF6EC9A8);
  static const containerTabs = <DeviceTabSpec>[];

  /// Delay panel follows the 170px-wide layout in daw_elements.svg.
  static const double designWidth = 170;

  static const timeModes = <String>['Time', '16th', '8th', '4th'];
  static const blurModes = <String>['No Blur', 'Soft Blur', 'Wide Blur'];

  final DelayDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static double _timeToKnob(double milliseconds) {
    if (milliseconds <= 0) return 0;
    return (math.log(milliseconds.clamp(1, 5000)) / math.log(5000))
        .clamp(0.0, 1.0);
  }

  static double _knobToTime(double value) {
    if (value <= 0) return 0;
    return math.pow(5000, value).toDouble().clamp(0, 5000);
  }

  static double _frequencyToKnob(double frequency, double min, double max) =>
      (math.log(frequency.clamp(min, max) / min) / math.log(max / min))
          .clamp(0.0, 1.0);

  static double _knobToFrequency(double value, double min, double max) =>
      (min * math.pow(max / min, value)).toDouble().clamp(min, max);

  Widget _panelColumn(List<Widget> children) => Expanded(
        child: Container(
          height: 174,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF050508),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final timeMode =
        device.delayTimeMode.round().clamp(0, timeModes.length - 1);
    final blurMode =
        device.delayBlurMode.round().clamp(0, blurModes.length - 1);
    final isFreeTime = timeMode == 0;
    final timeValue = isFreeTime
        ? _timeToKnob(device.delayTimeMs)
        : ((device.delayNoteCount - 1) / 7).clamp(0.0, 1.0);
    final timeDisplay = isFreeTime
        ? (device.delayTimeMs >= 1000
            ? '${(device.delayTimeMs / 1000).toStringAsFixed(2)} s'
            : '${device.delayTimeMs.round()} ms')
        : '${device.delayNoteCount.round()}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 257,
        maxHeight: 257,
        child: SizedBox(
          height: 257,
          child: Column(
            children: [
              SizedBox(
                height: 174,
                child: Row(
                  children: [
                    _panelColumn([
                      _knob(
                        label: timeModes[timeMode],
                        value: timeValue,
                        paramId: 'timeMs',
                        accent: accent,
                        onParameterChanged: (_, v) => onParameterChanged(
                          isFreeTime ? 'timeMs' : 'noteCount',
                          isFreeTime
                              ? _knobToTime(v)
                              : 1 + (v * 7).roundToDouble(),
                        ),
                        modulatedParams: modulatedParams,
                        automatedParams: automatedParams,
                        modulationAmounts: modulationAmounts,
                        connectModeLfoId: connectModeLfoId,
                        onModulationAssign: onModulationAssign,
                        automationLinkActive: automationLinkActive,
                        onAutomationLinkTap: onAutomationLinkTap,
                        onAutomateParameter: onAutomateParameter,
                        displayValue: timeDisplay,
                        labelOptions: timeModes,
                        onLabelOptionSelected: (mode) => onParameterChanged(
                            'timeMode', timeModes.indexOf(mode).toDouble()),
                      ),
                      _knob(
                        label: blurModes[blurMode],
                        value: device.delayBlurAmount,
                        paramId: 'blurAmount',
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
                        displayValue:
                            '${(device.delayBlurAmount * 100).round()}%',
                        labelOptions: blurModes,
                        onLabelOptionSelected: (mode) => onParameterChanged(
                            'blurMode', blurModes.indexOf(mode).toDouble()),
                      ),
                    ]),
                    const SizedBox(width: 5),
                    _panelColumn([
                      _knob(
                        label: 'Input Ducking',
                        value: device.delayInputDucking,
                        paramId: 'inputDucking',
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
                        displayValue:
                            '${(device.delayInputDucking * 100).round()}%',
                      ),
                      _knob(
                        label: 'Feedback',
                        value: device.delayFeedback,
                        paramId: 'feedback',
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
                        displayValue:
                            '${(device.delayFeedback * 100).round()}%',
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 78,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF050508),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _knob(
                      label: 'Low Cut',
                      value: _frequencyToKnob(device.delayLowCutHz, 20, 2000),
                      paramId: 'lowCutHz',
                      accent: accent,
                      onParameterChanged: (_, v) => onParameterChanged(
                          'lowCutHz', _knobToFrequency(v, 20, 2000)),
                      modulatedParams: modulatedParams,
                      automatedParams: automatedParams,
                      modulationAmounts: modulationAmounts,
                      connectModeLfoId: connectModeLfoId,
                      onModulationAssign: onModulationAssign,
                      automationLinkActive: automationLinkActive,
                      onAutomationLinkTap: onAutomationLinkTap,
                      onAutomateParameter: onAutomateParameter,
                      displayValue: _formatHz(device.delayLowCutHz),
                    ),
                    _knob(
                      label: 'High Cut',
                      value:
                          _frequencyToKnob(device.delayHighCutHz, 2000, 20000),
                      paramId: 'highCutHz',
                      accent: accent,
                      onParameterChanged: (_, v) => onParameterChanged(
                          'highCutHz', _knobToFrequency(v, 2000, 20000)),
                      modulatedParams: modulatedParams,
                      automatedParams: automatedParams,
                      modulationAmounts: modulationAmounts,
                      connectModeLfoId: connectModeLfoId,
                      onModulationAssign: onModulationAssign,
                      automationLinkActive: automationLinkActive,
                      onAutomationLinkTap: onAutomationLinkTap,
                      onAutomateParameter: onAutomateParameter,
                      displayValue: _formatHz(device.delayHighCutHz),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DelayFxStrip extends StatelessWidget {
  const DelayFxStrip({
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
  final DelayDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => DelayFxPanel(
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

// ── Reverb ─────────────────────────────────────────────────────────────────

class ReverbFxPanel extends StatelessWidget {
  const ReverbFxPanel({
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

  static const accent = Color(0xFF7B6CF6);
  static const containerTabs = <DeviceTabSpec>[];

  /// Reverb — compact time FX card.
  static const double designWidth = 216;

  final ReverbDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return _timeFxSinglePage(
      rows: [
        _knobGridRow([
          _knob(
            label: 'Room',
            value: device.reverbRoomSize,
            paramId: 'roomSize',
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
            displayValue: '${(device.reverbRoomSize * 100).round()}%',
          ),
          _knob(
            label: 'Damping',
            value: device.reverbDamping,
            paramId: 'damping',
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
            displayValue: '${(device.reverbDamping * 100).round()}%',
          ),
          _knob(
            label: 'Wet',
            value: device.reverbWet,
            paramId: 'wet',
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
            displayValue: '${(device.reverbWet * 100).round()}%',
          ),
        ]),
      ],
    );
  }
}

class ReverbFxStrip extends StatelessWidget {
  const ReverbFxStrip({
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
  final ReverbDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => ReverbFxPanel(
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

// ── Chorus ─────────────────────────────────────────────────────────────────

class _ChorusModeGroup extends StatefulWidget {
  const _ChorusModeGroup({
    required this.value,
    required this.accent,
    required this.modulationActive,
    required this.modulationAmount,
    required this.automationActive,
    required this.connectModeActive,
    required this.linkModeActive,
    required this.onChanged,
    this.onModulationAssign,
    this.onAutomationLinkTap,
    this.onAutomateRequest,
  });

  final double value;
  final Color accent;
  final bool modulationActive;
  final double modulationAmount;
  final bool automationActive;
  final bool connectModeActive;
  final bool linkModeActive;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onModulationAssign;
  final VoidCallback? onAutomationLinkTap;
  final VoidCallback? onAutomateRequest;

  @override
  State<_ChorusModeGroup> createState() => _ChorusModeGroupState();
}

class _ChorusModulationLinePainter extends CustomPainter {
  const _ChorusModulationLinePainter({
    required this.value,
    required this.amount,
    required this.inAssignment,
  });

  final double value;
  final double amount;
  final bool inAssignment;

  @override
  void paint(Canvas canvas, Size size) {
    final start = (value.clamp(0.0, 3.0) / 3.0) * size.width;
    final end =
        (start + amount.clamp(-1.0, 1.0) * size.width).clamp(0.0, size.width);
    canvas.drawLine(
      Offset(start, size.height - 2.5),
      Offset(end, size.height - 2.5),
      Paint()
        ..color = Colors.white.withValues(alpha: inAssignment ? .9 : .6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChorusModulationLinePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.amount != amount ||
      oldDelegate.inAssignment != inAssignment;
}

class _ChorusModeGroupState extends State<_ChorusModeGroup>
    with SingleTickerProviderStateMixin {
  static const labels = ['Classic', 'Ensemble', 'Dimension', 'Drift'];
  bool _assigning = false;
  bool _highlightsVisible = true;
  double _startY = 0;
  double _assignment = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool get _pulseActive => widget.connectModeActive || widget.linkModeActive;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: .15, end: .45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ChorusModeGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.connectModeActive || oldWidget.linkModeActive;
    if (_pulseActive && !wasActive) {
      _pulseController.repeat(reverse: true);
    } else if (!_pulseActive && wasActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _longPress() {
    HapticFeedback.mediumImpact();
    if (widget.linkModeActive) {
      widget.onAutomationLinkTap?.call();
    } else if (!widget.connectModeActive) {
      widget.onAutomateRequest?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value.round().clamp(0, 3);
    final shownAmount = _assigning ? _assignment : widget.modulationAmount;
    final pulseAccent =
        widget.linkModeActive ? const Color(0xFFB48CFF) : widget.accent;
    final showPulse = _pulseActive && _highlightsVisible;
    final showModulationAmount = _assigning
        ? shownAmount.abs() > 0
        : widget.modulationActive && shownAmount.abs() > 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.linkModeActive ? widget.onAutomationLinkTap : null,
      onLongPress: widget.connectModeActive ? null : _longPress,
      onLongPressStart: widget.connectModeActive
          ? (details) {
              HapticFeedback.mediumImpact();
              _pulseController.stop();
              _startY = details.localPosition.dy;
              setState(() {
                _highlightsVisible = false;
                _assigning = true;
                _assignment = 0;
              });
            }
          : null,
      onLongPressMoveUpdate: widget.connectModeActive
          ? (details) => setState(() {
                _assignment = ((_startY - details.localPosition.dy) / 100)
                    .clamp(-1.0, 1.0);
              })
          : null,
      onLongPressEnd: widget.connectModeActive
          ? (_) {
              widget.onModulationAssign?.call(_assignment);
              _pulseController.reset();
              if (_pulseActive) _pulseController.repeat(reverse: true);
              setState(() {
                _highlightsVisible = true;
                _assigning = false;
                _assignment = 0;
              });
            }
          : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Container(
          key: const ValueKey('chorus-mode-group'),
          height: 36,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              pulseAccent.withValues(
                alpha: showPulse ? _pulseAnimation.value : 0,
              ),
              const Color(0xFF121218),
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: showPulse
                  ? pulseAccent.withValues(alpha: .75)
                  : Colors.white.withValues(alpha: .08),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    for (var index = 0; index < labels.length; index++) ...[
                      Expanded(
                        child: Material(
                          color: index == selected
                              ? widget.accent.withValues(alpha: .18)
                              : Colors.transparent,
                          child: InkWell(
                            key: ValueKey('chorus-mode-${labels[index]}'),
                            onTap: widget.linkModeActive
                                ? widget.onAutomationLinkTap
                                : () => widget.onChanged(index.toDouble()),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  labels[index],
                                  style: TextStyle(
                                    color: index == selected
                                        ? widget.accent
                                        : Colors.white38,
                                    fontSize: 8,
                                    fontWeight: index == selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (index < labels.length - 1)
                        Container(
                          width: 1,
                          color: Colors.white.withValues(alpha: .06),
                        ),
                    ],
                  ],
                ),
              ),
              if (showModulationAmount)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const ValueKey('chorus-mode-modulation-line'),
                      painter: _ChorusModulationLinePainter(
                        value: widget.value,
                        amount: shownAmount,
                        inAssignment: _assigning,
                      ),
                    ),
                  ),
                ),
              if (widget.automationActive)
                Positioned(
                  left: 3,
                  top: 3,
                  child: IgnorePointer(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB48CFF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: .5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChorusFxPanel extends StatelessWidget {
  const ChorusFxPanel({
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

  static const accent = Color(0xFFE8A54B);
  static const containerTabs = <DeviceTabSpec>[];

  /// Chorus — compact time FX card.
  static const double designWidth = 216;

  final ChorusDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final mode = device.modeMorph.round().clamp(0, 3);
    final bank = switch (mode) {
      1 => device.ensemble,
      2 => device.dimension,
      3 => device.drift,
      _ => device.classic,
    };
    final definitions = switch (mode) {
      1 => <(String, String, String Function(double))>[
          (
            'Rate',
            'ensembleRate',
            (v) => '${(0.05 + v * 1.95).toStringAsFixed(2)} Hz'
          ),
          ('Depth', 'ensembleDepth', (v) => '${(v * 100).round()}%'),
          ('Voices', 'ensembleVoices', (v) => '${2 + (v * 2).round()}'),
          ('Spread', 'ensembleSpread', (v) => '${(v * 100).round()}%'),
          ('Drift', 'ensembleDrift', (v) => '${(v * 100).round()}%'),
          ('Tone', 'ensembleTone', (v) => _formatHz(3000 + v * 17000)),
        ],
      2 => <(String, String, String Function(double))>[
          ('Amount', 'dimensionAmount', (v) => '${(v * 100).round()}%'),
          (
            'Delay',
            'dimensionDelay',
            (v) => '${(4 + v * 20).toStringAsFixed(1)} ms'
          ),
          ('Spread', 'dimensionSpread', (v) => '${(v * 100).round()}%'),
          ('Motion', 'dimensionMotion', (v) => '${(v * 100).round()}%'),
          (
            'Low Cut',
            'dimensionLowCut',
            (v) => _formatHz((20 * math.pow(50, v)).toDouble())
          ),
          (
            'High Cut',
            'dimensionHighCut',
            (v) => _formatHz((2000 * math.pow(10, v)).toDouble())
          ),
        ],
      3 => <(String, String, String Function(double))>[
          (
            'Speed',
            'driftSpeed',
            (v) => '${(0.02 + v * 0.98).toStringAsFixed(2)} Hz'
          ),
          ('Depth', 'driftDepth', (v) => '${(v * 100).round()}%'),
          ('Wander', 'driftWander', (v) => '${(v * 100).round()}%'),
          (
            'Delay',
            'driftDelay',
            (v) => '${(3 + v * 27).toStringAsFixed(1)} ms'
          ),
          ('Stereo', 'driftStereo', (v) => '${(v * 100).round()}%'),
          ('Tone', 'driftTone', (v) => _formatHz(2500 + v * 17500)),
        ],
      _ => <(String, String, String Function(double))>[
          (
            'Rate',
            'classicRate',
            (v) => '${(0.1 + v * 4.9).toStringAsFixed(2)} Hz'
          ),
          ('Depth', 'classicDepth', (v) => '${(v * 100).round()}%'),
          (
            'Delay',
            'classicDelay',
            (v) => '${(2 + v * 18).toStringAsFixed(1)} ms'
          ),
          ('Feedback', 'classicFeedback', (v) => '${(v * 80).round()}%'),
          ('Phase', 'classicPhase', (v) => '${(v * 180).round()}°'),
          (
            'Shape',
            'classicShape',
            (v) => v < .33
                ? 'Sine'
                : v > .67
                    ? 'Triangle'
                    : 'Morph'
          ),
        ],
    };

    _TimeFxKnob control(int index) => _knob(
          label: definitions[index].$1,
          value: bank[index],
          paramId: definitions[index].$2,
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
          displayValue: definitions[index].$3(bank[index]),
        );

    return _timeFxSinglePage(
      rows: [
        _ChorusModeGroup(
          value: device.modeMorph,
          accent: accent,
          modulationActive: modulatedParams.contains('modeMorph'),
          modulationAmount: modulationAmounts['modeMorph'] ?? 0,
          automationActive: automatedParams.contains('modeMorph'),
          connectModeActive: connectModeLfoId != null,
          linkModeActive: automationLinkActive,
          onChanged: (value) => onParameterChanged('modeMorph', value),
          onModulationAssign: onModulationAssign == null
              ? null
              : (amount) => onModulationAssign!('modeMorph', amount),
          onAutomationLinkTap: onAutomationLinkTap == null
              ? null
              : () => onAutomationLinkTap!('modeMorph'),
          onAutomateRequest: onAutomateParameter == null
              ? null
              : () => onAutomateParameter!('modeMorph'),
        ),
        _knobGridRow([
          control(0),
          control(1),
          control(2),
        ]),
        _knobGridRow([
          control(3),
          control(4),
          control(5),
        ]),
      ],
    );
  }
}

class ChorusFxStrip extends StatelessWidget {
  const ChorusFxStrip({
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
  final ChorusDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => ChorusFxPanel(
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

// ── Phaser ─────────────────────────────────────────────────────────────────

class PhaserFxPanel extends StatelessWidget {
  const PhaserFxPanel({
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

  static const accent = Color(0xFFE8A0C8);
  static const containerTabs = <DeviceTabSpec>[];

  /// Phaser — compact time FX card.
  static const double designWidth = 216;

  final PhaserDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final double normFreq =
        math.log(device.phaserCentreFrequencyHz.clamp(20.0, 20000.0) / 20.0) /
            math.log(1000.0);
    return _timeFxSinglePage(
      rows: [
        _knobGridRow([
          _knob(
            label: 'Depth',
            value: device.phaserDepth,
            paramId: 'depth',
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
            displayValue: '${(device.phaserDepth * 100).round()}%',
          ),
          _knob(
            label: 'Rate',
            value: (device.phaserRateHz - 0.1) / (5 - 0.1),
            paramId: 'rateHz',
            accent: accent,
            onParameterChanged: (id, v) =>
                onParameterChanged(id, 0.1 + v * 4.9),
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${device.phaserRateHz.toStringAsFixed(1)} Hz',
          ),
          _knob(
            label: 'Feedback',
            value: device.phaserFeedback,
            paramId: 'feedback',
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
            displayValue: '${(device.phaserFeedback * 100).round()}%',
          ),
        ]),
        _knobGridRow([
          _knob(
            label: 'Centre',
            value: normFreq,
            paramId: 'centreFrequencyHz',
            accent: accent,
            onParameterChanged: (id, v) =>
                onParameterChanged(id, 20.0 * math.pow(1000.0, v)),
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: _formatHz(device.phaserCentreFrequencyHz),
          ),
          null,
          null,
        ]),
      ],
    );
  }
}

class PhaserFxStrip extends StatelessWidget {
  const PhaserFxStrip({
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
  final PhaserDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => PhaserFxPanel(
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
