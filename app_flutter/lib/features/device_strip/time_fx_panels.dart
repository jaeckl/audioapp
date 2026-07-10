import 'dart:math' as math;
import 'package:flutter/gestures.dart';
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

enum ReverbViewTab { tail, tone, mod }

class ReverbHeaderActions extends StatefulWidget {
  const ReverbHeaderActions({
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
  State<ReverbHeaderActions> createState() => _ReverbHeaderActionsState();
}

class _ReverbHeaderActionsState extends State<ReverbHeaderActions>
    with SingleTickerProviderStateMixin {
  static const _modes = ['ROOM', 'PLATE', 'HALL', 'SPACE'];
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  bool _assigning = false;
  double _startY = 0;
  double _amount = 0;

  bool get _pulseActive =>
      widget.connectModeLfoId != null || widget.automationLinkActive;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse = Tween<double>(begin: .1, end: .35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ReverbHeaderActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive =
        oldWidget.connectModeLfoId != null || oldWidget.automationLinkActive;
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

  @override
  Widget build(BuildContext context) {
    const accent = ReverbFxPanel.accent;
    final mode = widget.device.modeMorph.round().clamp(0, 3);
    final shownAmount =
        _assigning ? _amount : widget.modulationAmounts['modeMorph'] ?? 0;
    final pulseColor =
        widget.automationLinkActive ? const Color(0xFFB48CFF) : accent;
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (details) {
              HapticFeedback.mediumImpact();
              if (widget.connectModeLfoId != null) {
                _pulseController.stop();
                setState(() {
                  _assigning = true;
                  _startY = details.localPosition.dy;
                  _amount = 0;
                });
              } else if (widget.automationLinkActive) {
                widget.onAutomationLinkTap?.call('modeMorph');
              } else {
                widget.onAutomateParameter?.call('modeMorph');
              }
            },
            onLongPressMoveUpdate: widget.connectModeLfoId == null
                ? null
                : (details) => setState(() {
                      _amount = ((_startY - details.localPosition.dy) / 70)
                          .clamp(-1.0, 1.0);
                    }),
            onLongPressEnd: widget.connectModeLfoId == null
                ? null
                : (_) {
                    widget.onModulationAssign?.call('modeMorph', _amount);
                    _pulseController.reset();
                    if (_pulseActive) {
                      _pulseController.repeat(reverse: true);
                    }
                    setState(() {
                      _assigning = false;
                      _amount = 0;
                    });
                  },
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => SizedBox(
                key: const ValueKey('reverb-header-mode'),
                width: 57,
                height: 40,
                child: Stack(
                  children: [
                    PopupMenuButton<int>(
                      key: const ValueKey('reverb-mode-menu'),
                      tooltip: 'Reverb algorithm',
                      padding: EdgeInsets.zero,
                      color: const Color(0xFF22222E),
                      onSelected: (index) => widget.onParameterChanged(
                        'modeMorph',
                        index.toDouble(),
                      ),
                      itemBuilder: (context) => [
                        for (var index = 0; index < _modes.length; index++)
                          PopupMenuItem<int>(
                            value: index,
                            height: 34,
                            child: Text(
                              _modes[index],
                              style: TextStyle(
                                color: index == mode ? accent : Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _modes[mode],
                              style: TextStyle(
                                color: _pulseActive
                                    ? Color.lerp(
                                        Colors.white60,
                                        pulseColor,
                                        _pulse.value,
                                      )
                                    : Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .25,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if ((widget.modulatedParams.contains('modeMorph') ||
                            _assigning) &&
                        shownAmount.abs() > 0)
                      Positioned(
                        left: shownAmount < 0 ? null : 5,
                        right: shownAmount < 0 ? 5 : null,
                        bottom: 7,
                        width: 44 * shownAmount.abs().clamp(0.05, 1.0),
                        child: ColoredBox(
                          color: pulseColor,
                          child: const SizedBox(height: 2),
                        ),
                      ),
                    if (widget.automatedParams.contains('modeMorph'))
                      const Positioned(
                        left: 2,
                        top: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFB48CFF),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 6, height: 6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('reverb-freeze'),
              customBorder: const CircleBorder(),
              onTap: () => widget.onParameterChanged(
                'freeze',
                widget.device.freeze >= .5 ? 0 : 1,
              ),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                if (widget.automationLinkActive) {
                  widget.onAutomationLinkTap?.call('freeze');
                } else {
                  widget.onAutomateParameter?.call('freeze');
                }
              },
              child: SizedBox(
                width: 36,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.ac_unit,
                      size: 19,
                      color:
                          widget.device.freeze >= .5 ? accent : Colors.white54,
                    ),
                    if (widget.automatedParams.contains('freeze'))
                      const Positioned(
                        left: 3,
                        top: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFB48CFF),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 5, height: 5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReverbResponseEditor extends StatefulWidget {
  const _ReverbResponseEditor({
    required this.device,
    required this.view,
    required this.accent,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeActive,
    required this.linkModeActive,
    this.onModulationAssign,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final ReverbDeviceSnapshot device;
  final ReverbViewTab view;
  final Color accent;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final bool connectModeActive;
  final bool linkModeActive;
  final TimeFxModulationAssign onModulationAssign;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  State<_ReverbResponseEditor> createState() => _ReverbResponseEditorState();
}

class _ReverbResponseEditorState extends State<_ReverbResponseEditor>
    with SingleTickerProviderStateMixin {
  String? _dragParameter;
  String? _assignmentParameter;
  double _assignmentStartY = 0;
  double _assignmentAmount = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  bool get _pulseActive => widget.connectModeActive || widget.linkModeActive;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse = Tween<double>(begin: .08, end: .3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ReverbResponseEditor oldWidget) {
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

  String _parameterAt(Offset position, Size size) {
    if (widget.view == ReverbViewTab.tail) {
      final preX = 12 + widget.device.preDelay * 55;
      final decayX = 70 + widget.device.decay * (size.width - 82);
      return (position.dx - preX).abs() < (position.dx - decayX).abs()
          ? 'preDelay'
          : 'decay';
    }
    if (widget.view == ReverbViewTab.mod) return 'modulation';
    final lowX = 12 + widget.device.lowCut * 58;
    final highX = size.width - 12 - (1 - widget.device.highCut) * 58;
    final duckX = 12 + widget.device.ducking * (size.width - 24);
    final dampingX = 70 + widget.device.damping * (size.width - 140);
    final distances = <String, double>{
      'lowCut': (position - Offset(lowX, size.height * .3)).distance,
      'highCut': (position - Offset(highX, size.height * .3)).distance,
      'ducking': (position - Offset(duckX, size.height - 11)).distance,
      'damping': (position - Offset(dampingX, size.height * .46)).distance,
    };
    return distances.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  void _updateParameter(String parameter, Offset position, Size size) {
    final value = switch (parameter) {
      'preDelay' => ((position.dx - 12) / 55).clamp(0.0, 1.0),
      'decay' => ((position.dx - 70) / (size.width - 82)).clamp(0.0, 1.0),
      'lowCut' => ((position.dx - 12) / 58).clamp(0.0, 1.0),
      'highCut' => (1 - (size.width - 12 - position.dx) / 58).clamp(0.0, 1.0),
      'ducking' => ((position.dx - 12) / (size.width - 24)).clamp(0.0, 1.0),
      'damping' => ((position.dx - 70) / (size.width - 140)).clamp(0.0, 1.0),
      'modulation' => ((position.dx - 12) / (size.width - 24)).clamp(0.0, 1.0),
      _ => 0.0,
    };
    widget.onParameterChanged(parameter, value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (details) {
              if (widget.linkModeActive) {
                HapticFeedback.mediumImpact();
                widget.onAutomationLinkTap
                    ?.call(_parameterAt(details.localPosition, size));
              }
            },
            onHorizontalDragStart: widget.connectModeActive ||
                    widget.linkModeActive
                ? null
                : (details) =>
                    _dragParameter = _parameterAt(details.localPosition, size),
            onHorizontalDragUpdate:
                widget.connectModeActive || widget.linkModeActive
                    ? null
                    : (details) => _updateParameter(
                          _dragParameter ??
                              _parameterAt(details.localPosition, size),
                          details.localPosition,
                          size,
                        ),
            onHorizontalDragEnd: (_) => _dragParameter = null,
            onLongPressStart: (details) {
              final parameter = _parameterAt(details.localPosition, size);
              HapticFeedback.mediumImpact();
              if (widget.connectModeActive) {
                _pulseController.stop();
                setState(() {
                  _assignmentParameter = parameter;
                  _assignmentStartY = details.localPosition.dy;
                  _assignmentAmount = 0;
                });
              } else {
                widget.onAutomateParameter?.call(parameter);
              }
            },
            onLongPressMoveUpdate: widget.connectModeActive
                ? (details) => setState(() {
                      _assignmentAmount =
                          ((_assignmentStartY - details.localPosition.dy) / 80)
                              .clamp(-1.0, 1.0);
                    })
                : null,
            onLongPressEnd: widget.connectModeActive
                ? (_) {
                    if (_assignmentParameter != null) {
                      widget.onModulationAssign
                          ?.call(_assignmentParameter!, _assignmentAmount);
                    }
                    _pulseController.reset();
                    if (_pulseActive) {
                      _pulseController.repeat(reverse: true);
                    }
                    setState(() {
                      _assignmentParameter = null;
                      _assignmentAmount = 0;
                    });
                  }
                : null,
            child: Container(
              key: const ValueKey('reverb-response-editor'),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  widget.accent.withValues(
                    alpha: _pulseActive ? _pulse.value : 0,
                  ),
                  const Color(0xFF050508),
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _pulseActive
                      ? widget.accent.withValues(alpha: .65)
                      : Colors.white.withValues(alpha: .1),
                ),
              ),
              child: CustomPaint(
                painter: _ReverbResponsePainter(
                  view: widget.view,
                  device: widget.device,
                  accent: widget.accent,
                  modulatedParams: widget.modulatedParams,
                  automatedParams: widget.automatedParams,
                  modulationAmounts: widget.modulationAmounts,
                  assignmentParameter: _assignmentParameter,
                  assignmentAmount: _assignmentAmount,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReverbResponsePainter extends CustomPainter {
  const _ReverbResponsePainter({
    required this.view,
    required this.device,
    required this.accent,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.assignmentParameter,
    required this.assignmentAmount,
  });

  final ReverbViewTab view;
  final ReverbDeviceSnapshot device;
  final Color accent;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final String? assignmentParameter;
  final double assignmentAmount;

  void _text(Canvas canvas, String text, Offset offset, Color color,
      {double size = 7, FontWeight weight = FontWeight.w700}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _handle(Canvas canvas, String parameter, Offset center) {
    canvas.drawCircle(
      center,
      14,
      Paint()..color = accent.withValues(alpha: .12),
    );
    canvas.drawCircle(center, 6, Paint()..color = accent);
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke,
    );
    final amount = assignmentParameter == parameter
        ? assignmentAmount
        : modulationAmounts[parameter] ?? 0;
    if ((modulatedParams.contains(parameter) ||
            assignmentParameter == parameter) &&
        amount.abs() > 0) {
      canvas.drawLine(
        center,
        Offset(center.dx + amount * 28, center.dy),
        Paint()
          ..color = Colors.white60
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    if (automatedParams.contains(parameter)) {
      canvas.drawCircle(
        center.translate(7, -7),
        2.4,
        Paint()..color = const Color(0xFFB48CFF),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mode = [
      'ROOM',
      'PLATE',
      'HALL',
      'SPACE'
    ][device.modeMorph.round().clamp(0, 3)];
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .055)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), grid);
    }

    if (view == ReverbViewTab.tail) {
      final baseY = size.height - 11;
      final peakY = 25.0;
      final preX = 12 + device.preDelay * 55;
      final decayX = 70 + device.decay * (size.width - 82);
      _text(
        canvas,
        '$mode  ·  PRE ${(device.preDelay * 250).round()} ms  ·  RT60 ${(.15 * math.pow(100, device.decay)).toStringAsFixed(1)} s',
        const Offset(8, 8),
        Colors.white60,
        size: 8,
      );
      for (var i = 0; i < 6; i++) {
        final x = preX - 22 + i * 4.2;
        final height = 14 + ((i * 17) % 42);
        canvas.drawLine(
          Offset(x, baseY),
          Offset(x, baseY - height),
          Paint()
            ..color = accent.withValues(alpha: .65)
            ..strokeWidth = 1.1,
        );
      }
      final path = Path()
        ..moveTo(preX, baseY)
        ..cubicTo(
          preX + 8,
          peakY,
          preX + 28,
          peakY,
          decayX,
          baseY - 9,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      _handle(canvas, 'preDelay', Offset(preX, baseY));
      _handle(canvas, 'decay', Offset(decayX, baseY - 9));
    } else if (view == ReverbViewTab.tone) {
      final y = size.height * .3;
      final lowX = 12 + device.lowCut * 58;
      final highX = size.width - 12 - (1 - device.highCut) * 58;
      final dampingX = 70 + device.damping * (size.width - 140);
      _text(
        canvas,
        'LOW ${_formatHz((20 * math.pow(50, device.lowCut)).toDouble())}  ·  DAMP ${(device.damping * 100).round()}%  ·  HIGH ${_formatHz((2000 * math.pow(10, device.highCut)).toDouble())}  ·  DUCK ${(device.ducking * 100).round()}%',
        const Offset(8, 8),
        Colors.white60,
        size: 8,
      );
      final path = Path()
        ..moveTo(6, size.height - 20)
        ..cubicTo(lowX - 10, size.height - 20, lowX - 7, y, lowX, y)
        ..lineTo(highX, y + (1 - device.damping) * 28)
        ..cubicTo(highX + 7, size.height - 20, size.width - 9, size.height - 20,
            size.width - 6, size.height - 20);
      canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      _handle(canvas, 'lowCut', Offset(lowX, y));
      _handle(canvas, 'highCut', Offset(highX, y + (1 - device.damping) * 28));
      _handle(canvas, 'damping', Offset(dampingX, size.height * .46));
      final duckX = 12 + device.ducking * (size.width - 24);
      canvas.drawLine(
        Offset(12, size.height - 11),
        Offset(size.width - 12, size.height - 11),
        Paint()
          ..color = Colors.white12
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(12, size.height - 11),
        Offset(duckX, size.height - 11),
        Paint()
          ..color = accent
          ..strokeWidth = 2,
      );
      _handle(canvas, 'ducking', Offset(duckX, size.height - 11));
    } else {
      final amplitude = 12 + device.modulation * (size.height * .38);
      final path = Path();
      for (var x = 8.0; x <= size.width - 8; x += 2) {
        final phase = (x - 8) / (size.width - 16) * math.pi * 4;
        final y = size.height * .5 + math.sin(phase) * amplitude;
        if (x == 8) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      for (var line = 0; line < 4; line++) {
        canvas.drawPath(
          path.shift(Offset(0, line * 6.0 - 9)),
          Paint()
            ..color = accent.withValues(alpha: .08 + line * .05)
            ..style = PaintingStyle.stroke,
        );
      }
      final handleX = 12 + device.modulation * (size.width - 24);
      _handle(canvas, 'modulation', Offset(handleX, size.height - 13));
      _text(
        canvas,
        '$mode  ·  DEPTH ${(device.modulation * 100).round()}%  ·  8-LINE MOTION',
        const Offset(8, 8),
        Colors.white60,
        size: 8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReverbResponsePainter oldDelegate) => true;
}

class ReverbFxPanel extends StatelessWidget {
  const ReverbFxPanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab = ReverbViewTab.tail,
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
  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'TAIL', icon: Icons.multiline_chart),
    DeviceTabSpec(label: 'TONE', icon: Icons.equalizer),
    DeviceTabSpec(label: 'MOD', icon: Icons.waves),
  ];

  /// Version C — wide editor plus a dedicated parameter column.
  static const double designWidth = 320;

  final ReverbDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final ReverbViewTab selectedTab;
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
    _TimeFxKnob control(
            String label, String parameter, double value, String display,
            {double knobSize = 52}) =>
        _knob(
          label: label,
          value: value,
          paramId: parameter,
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
          displayValue: display,
          size: knobSize,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 6, 5, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ReverbResponseEditor(
                    device: device,
                    view: selectedTab,
                    accent: accent,
                    onParameterChanged: onParameterChanged,
                    modulatedParams: modulatedParams,
                    automatedParams: automatedParams,
                    modulationAmounts: modulationAmounts,
                    connectModeActive: connectModeLfoId != null,
                    linkModeActive: automationLinkActive,
                    onModulationAssign: onModulationAssign,
                    onAutomationLinkTap: onAutomationLinkTap,
                    onAutomateParameter: onAutomateParameter,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    control(
                      'Pre-delay',
                      'preDelay',
                      device.preDelay,
                      '${(device.preDelay * 250).round()} ms',
                    ),
                    control(
                      'Mod',
                      'modulation',
                      device.modulation,
                      '${(device.modulation * 100).round()}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: Container(
              key: const ValueKey('reverb-parameter-column'),
              decoration: BoxDecoration(
                color: const Color(0xFF050508),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  control(
                    'Decay',
                    'decay',
                    device.decay,
                    '${(.15 * math.pow(100, device.decay)).toStringAsFixed(1)} s',
                    knobSize: 48,
                  ),
                  control(
                    'Size',
                    'size',
                    device.size,
                    '${(device.size * 100).round()}%',
                    knobSize: 48,
                  ),
                  control(
                    'Diffusion',
                    'diffusion',
                    device.diffusion,
                    '${(device.diffusion * 100).round()}%',
                    knobSize: 48,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReverbFxStrip extends StatelessWidget {
  const ReverbFxStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab = ReverbViewTab.tail,
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
  final ReverbViewTab selectedTab;
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
        selectedTab: selectedTab,
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

class _MorphModeGroup extends StatefulWidget {
  const _MorphModeGroup({
    required this.labels,
    required this.keyPrefix,
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

  final List<String> labels;
  final String keyPrefix;
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
  State<_MorphModeGroup> createState() => _MorphModeGroupState();
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

class _MorphModeGroupState extends State<_MorphModeGroup>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant _MorphModeGroup oldWidget) {
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
          key: ValueKey('${widget.keyPrefix}-group'),
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
                    for (var index = 0;
                        index < widget.labels.length;
                        index++) ...[
                      Expanded(
                        child: Material(
                          color: index == selected
                              ? widget.accent.withValues(alpha: .18)
                              : Colors.transparent,
                          child: InkWell(
                            key: ValueKey(
                              '${widget.keyPrefix}-${widget.labels[index]}',
                            ),
                            onTap: widget.linkModeActive
                                ? widget.onAutomationLinkTap
                                : () => widget.onChanged(index.toDouble()),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.labels[index],
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
                      if (index < widget.labels.length - 1)
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
                      key: ValueKey('${widget.keyPrefix}-modulation-line'),
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
        _MorphModeGroup(
          labels: const ['Classic', 'Ensemble', 'Dimension', 'Drift'],
          keyPrefix: 'chorus-mode',
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
