import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/device_snapshot.dart';
import 'device_automation_spinner.dart';
import 'device_knob_sizes.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'effective_parameter_binding.dart';
import 'rotary_knob.dart';

part 'restore_fx_panels_dc_offset_fx_panel.dart';
part 'restore_fx_panels_dc_offset_fx_strip.dart';
part 'restore_fx_panels_de_crackler_fx_panel.dart';
part 'restore_fx_panels_de_crackler_fx_strip.dart';
part 'restore_fx_panels_de_esser_fx_panel.dart';
part 'restore_fx_panels_de_esser_fx_strip.dart';
part 'restore_fx_panels_de_hum_fx_panel.dart';
part 'restore_fx_panels_de_hum_fx_strip.dart';
part 'restore_fx_panels_de_noise_fx_panel.dart';
part 'restore_fx_panels_de_noise_fx_strip.dart';

typedef RestoreFxParameterChanged = void Function(
    String parameterId, double value);
typedef RestoreFxModulationAssign = void Function(String paramId, double amount)?;

const _kKnobGap = 4.0;
const _kComboHeight = 40.0;
const _kPadTop = 14.0;
const _kPadBottom = 6.0;
const _kPadH = 6.0;
/// RotaryKnob host is size+8 wide; chrome below size is +4+labelGap+label.
const _kKnobHostExtraW = 8.0;
const _kKnobExtraH = 20.0;

double _knobSizeFor({
  required double maxHeight,
  required double maxWidth,
  required int knobCount,
  required bool hasCombo,
}) {
  if (knobCount <= 0) return DeviceKnobSizes.compact;
  final comboBlock = hasCombo ? _kComboHeight + 6.0 : 0.0;
  final gaps = knobCount > 1 ? (knobCount - 1) * _kKnobGap : 0.0;
  final availH =
      maxHeight - _kPadTop - _kPadBottom - comboBlock - gaps;
  final byHeight = (availH / knobCount) - _kKnobExtraH;
  final byWidth = maxWidth - _kKnobHostExtraW;
  return math
      .min(byHeight, byWidth)
      .clamp(40.0, DeviceStripMetrics.dynamicsFxKnobSize);
}

/// Narrow vertical stack: optional combobox + knobs sized to body.
Widget _restoreFxColumn({
  Widget Function(double width)? comboBuilder,
  required List<Widget> Function(double knobSize) knobsBuilder,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxH = constraints.hasBoundedHeight && constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : DeviceStripMetrics.height;
      final maxW = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 96.0;
      final innerW = (maxW - _kPadH * 2).clamp(48.0, maxW);
      final hasCombo = comboBuilder != null;
      final probe = knobsBuilder(DeviceStripMetrics.dynamicsFxKnobSize);
      final knobSize = _knobSizeFor(
        maxHeight: maxH,
        maxWidth: innerW,
        knobCount: probe.length,
        hasCombo: hasCombo,
      );
      final knobs = knobSize == DeviceStripMetrics.dynamicsFxKnobSize
          ? probe
          : knobsBuilder(knobSize);

      // Top inset under header + vertical center so leftover height is not
      // all dumped as empty bottom space.
      return ClipRect(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _kPadH,
            _kPadTop,
            _kPadH,
            _kPadBottom,
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: innerW),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (comboBuilder != null) ...[
                    comboBuilder(innerW),
                    const SizedBox(height: 6),
                  ],
                  for (var i = 0; i < knobs.length; i++) ...[
                    if (i > 0) const SizedBox(height: _kKnobGap),
                    knobs[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RestoreFxKnob extends StatelessWidget {
  const _RestoreFxKnob({
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
    required this.size,
    this.displayValue,
    this.enabled = true,
  });

  final String label;
  final double value;
  final String paramId;
  final Color accent;
  final RestoreFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final RestoreFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final double size;
  final String? displayValue;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final knob = RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: size,
      displayValue: displayValue,
      accentColor: accent,
      modulationActive: modulatedParams.contains(paramId),
      automationActive: automatedParams.contains(paramId),
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
      parameterId: paramId,
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
      onChanged: (v) {
        if (enabled) onParameterChanged(paramId, v);
      },
    );
    if (enabled) return knob;
    return Opacity(opacity: 0.35, child: IgnorePointer(child: knob));
  }
}

_RestoreFxKnob _knob({
  required String label,
  required double value,
  required String paramId,
  required Color accent,
  required RestoreFxParameterChanged onParameterChanged,
  required Set<String> modulatedParams,
  required Set<String> automatedParams,
  required Map<String, double> modulationAmounts,
  required int? connectModeLfoId,
  required RestoreFxModulationAssign onModulationAssign,
  required bool automationLinkActive,
  required ValueChanged<String>? onAutomationLinkTap,
  required ValueChanged<String>? onAutomateParameter,
  required double size,
  String? displayValue,
  bool enabled = true,
}) {
  return _RestoreFxKnob(
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
    size: size,
    displayValue: displayValue,
    enabled: enabled,
  );
}

/// Discrete restore mode combo — spinner owns long-press (mod/auto); tap opens menu.
class _RestoreCombo extends StatelessWidget {
  const _RestoreCombo({
    required this.paramId,
    required this.options,
    required this.selectedIndex,
    required this.accent,
    required this.onSelected,
    required this.keyPrefix,
    required this.width,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeLfoId,
    required this.onModulationAssign,
    required this.automationLinkActive,
    required this.onAutomationLinkTap,
    required this.onAutomateParameter,
  });

  final String paramId;
  final List<String> options;
  final int selectedIndex;
  final Color accent;
  final ValueChanged<int> onSelected;
  final String keyPrefix;
  final double width;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final RestoreFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  int _indexFromValue(double value) {
    if (options.length <= 1) return 0;
    if (options.length == 2) return value >= 0.5 ? 1 : 0;
    final stepped = (value * (options.length - 1)).round();
    return stepped.clamp(0, options.length - 1);
  }

  double _valueFromIndex(int index) {
    if (options.length <= 1) return 0;
    return index / (options.length - 1);
  }

  Future<void> _openMenu(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight =
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);
    final picked = await showMenu<int>(
      context: buttonContext,
      color: const Color(0xFF22222E),
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      items: [
        for (var i = 0; i < options.length; i++)
          PopupMenuItem<int>(
            value: i,
            height: 36,
            child: Text(
              options[i],
              style: TextStyle(
                fontSize: 12,
                color: i == selectedIndex.clamp(0, options.length - 1)
                    ? accent
                    : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final fallback = selectedIndex.clamp(0, options.length - 1);
    final liveActive = modulatedParams.contains(paramId) ||
        automatedParams.contains(paramId);
    final connectOrLink =
        connectModeLfoId != null || automationLinkActive;

    // Child must NOT force outer width — spinner border deflates inner constraints.
    // PopupMenuButton steals long-press; InkWell+showMenu keeps spinner mod/auto.
    // Opaque fill hides spinner pulse glow — go transparent in connect/link.
    return deviceAutomationSpinner(
      paramId: paramId,
      width: width,
      height: _kComboHeight,
      accentColor: accent,
      borderAlpha: connectOrLink ? 0.75 : 0.45,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
      child: SizedBox.expand(
        child: Material(
          color: connectOrLink
              ? Colors.transparent
              : const Color(0xFF0C0C11),
          borderRadius: BorderRadius.circular(5),
          clipBehavior: Clip.antiAlias,
          child: EffectiveParameterValueBuilder(
            parameterId: paramId,
            fallbackValue: _valueFromIndex(fallback),
            active: liveActive,
            builder: (context, liveValue) {
              final idx = liveActive ? _indexFromValue(liveValue) : fallback;
              return Builder(
                builder: (buttonContext) {
                  return InkWell(
                    key: ValueKey('$keyPrefix-combo'),
                    onTap: connectOrLink
                        ? null
                        : () => _openMenu(buttonContext),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              options[idx],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: accent,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18, color: Colors.white54),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
