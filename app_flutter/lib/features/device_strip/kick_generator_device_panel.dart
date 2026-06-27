import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'drum_model_tab_bar.dart';
import 'kick_envelope_preview.dart';
import 'kick_model.dart';
import 'kick_model_ui_registry.dart';
import 'rotary_knob.dart';

class KickGeneratorDevicePanel extends StatelessWidget {
  const KickGeneratorDevicePanel({
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

  final KickGeneratorDeviceSnapshot device;
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

  static const accent = DeviceStripTheme.kickGeneratorAccent;

  /// Kick generator — wide bench layout.
  static const double designWidth = 480;

  /// Kick bench uses header-only chrome — no container tabs.
  static const containerTabs = <DeviceTabSpec>[];

  @override
  Widget build(BuildContext context) {
    final modelIndex = KickModel.indexFromValue(device.kickModel);
    final knobs = KickModelUiRegistry.knobsForModelIndex(modelIndex);
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
                    child: KickEnvelopePreview(
                      pitch: device.kickPitch,
                      punch: device.kickPunch,
                      decay: device.kickDecay,
                      click: device.kickClick,
                      accent: accent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 1,
                  child: _modelSegment(context, modelIndex),
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
                      for (final spec in knobs.take(3)) _buildKnob(spec),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final spec in knobs.skip(3)) _buildKnob(spec),
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
              'KICK GENERATOR',
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

  Widget _modelSegment(BuildContext context, int selectedIndex) {
    return DrumModelTabBar(
      labels: KickModel.labels,
      selectedIndex: selectedIndex,
      accent: accent,
      isEnabled: KickModel.isSelectable,
      onSelected: (i) => onParameterChanged('kickModel', KickModel.valueFromIndex(i)),
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

  Widget _buildKnob(KickKnobSpec spec) {
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
