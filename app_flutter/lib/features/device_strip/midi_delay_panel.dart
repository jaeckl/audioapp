import 'package:flutter/material.dart';

import '../../bridge/device_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

class MidiDelayPanel extends StatelessWidget {
  const MidiDelayPanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
  });

  static const double designWidth = 210;
  static const containerTabs = <DeviceTabSpec>[];
  static const _accent = Color(0xFFA78BFA);
  static const _divisions = <({double value, String label})>[
    (value: 0.0625, label: '1/64'), (value: 0.125, label: '1/32'),
    (value: 0.25, label: '1/16'), (value: 0.5, label: '1/8'),
    (value: 1.0, label: '1/4'), (value: 2.0, label: '1/2'),
    (value: 4.0, label: '1/1'),
  ];

  final MidiDelayDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;

  @override
  Widget build(BuildContext context) {
    final selectedDivision = _divisions.map((entry) => entry.value).reduce(
      (a, b) => (a - device.division).abs() < (b - device.division).abs() ? a : b,
    );
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF12121A),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _accent.withValues(alpha: 0.35)),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, color: _accent, size: 25),
                    SizedBox(width: 8),
                    Text('MIDI DELAY', style: TextStyle(
                      color: _accent, fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('SECONDS')),
              ButtonSegment(value: true, label: Text('SYNC')),
            ],
            selected: {device.synced},
            onSelectionChanged: (value) => onParameterChanged(
              'midiDelayMode', value.first ? 1 : 0,
            ),
          ),
          const SizedBox(height: 10),
          if (!device.synced)
            RotaryKnob(
              label: 'Delay',
              value: (device.seconds / 2).clamp(0, 1),
              size: DeviceStripMetrics.dynamicsFxKnobSize,
              displayValue: '${device.seconds.toStringAsFixed(2)} s',
              accentColor: _accent,
              onChanged: (value) =>
                  onParameterChanged('midiDelaySeconds', value * 2),
            )
          else
            DropdownButton<double>(
              key: const ValueKey('midi-delay-division'),
              value: selectedDivision,
              dropdownColor: const Color(0xFF1B1B25),
              items: _divisions.map((entry) => DropdownMenuItem(
                value: entry.value,
                child: Text(entry.label),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  onParameterChanged('midiDelayDivision', value);
                }
              },
            ),
        ],
      ),
    );
  }
}
