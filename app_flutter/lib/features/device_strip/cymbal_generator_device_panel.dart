import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'cymbal_decay_preview.dart';
import 'cymbal_model.dart';
import 'cymbal_model_ui_registry.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'drum_model_tab_bar.dart';
import 'rotary_knob.dart';

class CymbalGeneratorDevicePanel extends StatelessWidget {
  const CymbalGeneratorDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.embeddedInCard = false,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final CymbalGeneratorDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final bool embeddedInCard;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const accent = DeviceStripTheme.cymbalGeneratorAccent;

  static const containerTabs = <DeviceTabSpec>[];

  @override
  Widget build(BuildContext context) {
    final modelIndex = CymbalModel.indexFromValue(device.cymbalModel);
    final knobs = CymbalModelUiRegistry.knobsForModelIndex(modelIndex);
    final bench = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: _previewBox(
                    child: CymbalDecayPreview(
                      color: device.cymbalColor,
                      decay: device.cymbalDecay,
                      accent: accent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 1,
                  child: DrumModelTabBar(
                    labels: CymbalModel.labels,
                    selectedIndex: modelIndex,
                    accent: accent,
                    isEnabled: CymbalModel.isSelectable,
                    onSelected: (i) =>
                        onParameterChanged('cymbalModel', CymbalModel.valueFromIndex(i)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final spec in knobs.take(2)) _buildKnob(spec),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final spec in knobs.skip(2)) _buildKnob(spec),
                      const SizedBox(width: DeviceKnobSizes.strip),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (embeddedInCard) {
      return bench;
    }

    return Material(
      color: const Color(0xFF1C1C24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(
              'CYMBAL GENERATOR',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(child: bench),
        ],
      ),
    );
  }

  Widget _previewBox({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: child),
    );
  }

  Widget _buildKnob(CymbalKnobSpec spec) {
    final value = spec.value(device);
    final paramId = spec.paramId;
    return RotaryKnob(
      label: spec.label,
      value: value.clamp(0.0, 1.0),
      size: DeviceKnobSizes.strip,
      displayValue: spec.format(value),
      accentColor: accent,
      modulationActive: modulatedParams.contains(paramId),
      automationActive: automatedParams.contains(paramId),
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
      connectModeActive: connectModeLfoId != null,
      onModulationAssign: onModulationAssign != null
          ? (amount) => onModulationAssign!(paramId, amount)
          : null,
      linkModeActive: automationLinkActive,
      onLinkTap: onAutomationLinkTap != null ? () => onAutomationLinkTap!(paramId) : null,
      onAutomateRequest:
          onAutomateParameter != null ? () => onAutomateParameter!(paramId) : null,
      onChanged: (v) => onParameterChanged(paramId, v),
    );
  }
}
