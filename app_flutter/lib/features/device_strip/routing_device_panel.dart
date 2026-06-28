import 'package:flutter/material.dart';

import '../../bridge/device_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

class RoutingSourceOption {
  const RoutingSourceOption(
      {required this.id, required this.label, required this.isMidi});
  final String id;
  final String label;
  final bool isMidi;
}

class RoutingDevicePanel extends StatelessWidget {
  const RoutingDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    required this.sources,
    required this.onSourceChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const double designWidth = 210;
  static const containerTabs = <DeviceTabSpec>[];

  final RoutingDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final List<RoutingSourceOption> sources;
  final ValueChanged<String> onSourceChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final accent = DeviceStripTheme.accentForDeviceType(device.type);
    final selectedId = sources.any((source) => source.id == device.sourceId)
        ? device.sourceId
        : null;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF12121A),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.call_received,
                      color: accent,
                      size: 25,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      device.isAudioRoute ? 'RECEIVE AUDIO' : 'RECEIVE MIDI',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('SOURCE',
              style: TextStyle(color: Colors.white38, fontSize: 9)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            key: const ValueKey('route-source'),
            initialValue: selectedId,
            isExpanded: true,
            dropdownColor: const Color(0xFF1B1B25),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
            hint: const Text('Choose source',
                style: TextStyle(color: Colors.white38)),
            items: sources
                .map((source) => DropdownMenuItem(
                      value: source.id,
                      child:
                          Text(source.label, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) onSourceChanged(value);
            },
          ),
          if (device.isAudioRoute) ...[
            const SizedBox(height: 9),
            RotaryKnob(
              label: 'Mix',
              value: device.routeMix,
              size: DeviceStripMetrics.dynamicsFxKnobSize,
              displayValue: '${(device.routeMix * 100).round()}%',
              accentColor: accent,
              modulationActive: modulatedParams.contains('routeMix'),
              automationActive: automatedParams.contains('routeMix'),
              modulationAmount: modulationAmounts['routeMix'] ?? 0,
              connectModeActive: connectModeLfoId != null,
              onModulationAssign: onModulationAssign == null
                  ? null
                  : (amount) => onModulationAssign!('routeMix', amount),
              linkModeActive: automationLinkActive,
              onLinkTap: onAutomationLinkTap == null
                  ? null
                  : () => onAutomationLinkTap!('routeMix'),
              onAutomateRequest: onAutomateParameter == null
                  ? null
                  : () => onAutomateParameter!('routeMix'),
              onChanged: (value) => onParameterChanged('routeMix', value),
            ),
          ],
        ],
      ),
    );
  }
}
