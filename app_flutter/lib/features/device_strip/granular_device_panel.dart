import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart';

part 'granular_device_panel_private_formant_orbit.dart';
part 'granular_device_panel_private_formant_orbit_painter.dart';
part 'granular_device_panel_private_region_drag.dart';
part 'granular_device_panel_private_sample_region_preview.dart';
part 'granular_device_panel_private_sample_region_preview_state.dart';
part 'granular_device_panel_private_sample_region_painter.dart';
part 'granular_device_panel_private_grain_cloud_preview.dart';
part 'granular_device_panel_private_grain_cloud_painter.dart';

class GranularDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['granular_formant_synth'];
  const GranularDevicePanel({
    super.key,
    required this.device,
    required this.sample,
    required this.tab,
    required this.playing,
    required this.playheadBeat,
    required this.onChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const double designWidth = 292;
  static const accent = Color(0xFFDA70D6);
  static const containerTabs = [
    DeviceTabSpec(icon: Icons.graphic_eq, label: 'SAMPLE'),
    DeviceTabSpec(icon: Icons.blur_on, label: 'GRAIN'),
    DeviceTabSpec(icon: Icons.record_voice_over, label: 'FORM'),
  ];

  final GranularDeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final int tab;
  final bool playing;
  final double playheadBeat;
  final void Function(String, double) onChanged;
  final Set<String> modulatedParams, automatedParams;
  final Map<String, double> modulationAmounts;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int? connectModeLfoId;
  final void Function(String, double)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap, onAutomateParameter;

  Widget knob(String label, String id, double value,
          [String? display, double size = DeviceKnobSizes.strip]) =>
      deviceAutomationKnob(
        label: label,
        value: value,
        displayValue: display,
        onChanged: (v) => onChanged(id, v),
        paramId: id,
        deviceId: device.id,
        modulatedParams: modulatedParams,
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        lfos: lfos,
        modEdges: modEdges,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
        accentColor: accent,
        size: size,
      );

  @override
  Widget build(BuildContext context) {
    if (tab == 2) {
      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: _FormantOrbit(
                x: device.formX,
                y: device.formY,
                onChanged: (x, y) {
                  onChanged('formX', x);
                  onChanged('formY', y);
                },
                xModulated: modulatedParams.contains('formX'),
                yModulated: modulatedParams.contains('formY'),
                xAutomated: automatedParams.contains('formX'),
                yAutomated: automatedParams.contains('formY'),
                connectMode: connectModeLfoId != null,
                automationLinkMode: automationLinkActive,
                onModulationAssign: onModulationAssign,
                onAutomationLinkTap: onAutomationLinkTap,
                onAutomateParameter: onAutomateParameter,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              knob('Shift', 'formant', device.formant, null,
                  DeviceKnobSizes.compact),
              knob('Color', 'character', device.character, null,
                  DeviceKnobSizes.compact),
              knob('Spread', 'spread', device.spread, null,
                  DeviceKnobSizes.compact),
              knob('Attack', 'attack', device.attack, null,
                  DeviceKnobSizes.compact),
              knob('Release', 'release', device.release, null,
                  DeviceKnobSizes.compact),
            ],
          ),
        ],
      );
    }

    final controls = tab == 0
        ? [
            knob('Position', 'position', device.position),
            knob('Scan', 'scan', device.scan),
            knob(
              'Pitch',
              'grainPitch',
              device.grainPitch,
              '${((device.grainPitch - .5) * 48).round()} st',
            ),
          ]
        : [
            knob('Size', 'grainSize', device.grainSize),
            knob('Density', 'density', device.density),
            knob('Spray', 'spray', device.spray),
          ];
    final regionLength = device.regionEnd - device.regionStart;
    final motion = playing
        ? (device.position + playheadBeat * (device.scan - .5) * .35) % 1.0
        : device.position;
    final livePosition = device.regionStart + motion * regionLength;
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFF111119),
              borderRadius: BorderRadius.circular(4),
            ),
            child: tab == 0
                ? _SampleRegionPreview(
                    peaks: sample?.waveformPeaks ?? const [],
                    sampleName: device.sampleId.isEmpty
                        ? 'LOAD SAMPLE'
                        : (sample?.name ?? 'SAMPLE'),
                    regionStart: device.regionStart,
                    regionEnd: device.regionEnd,
                    position: livePosition,
                    scan: device.scan,
                    enabled: sample != null,
                    onPositionChanged: (absolute) => onChanged(
                      'position',
                      ((absolute - device.regionStart) / regionLength)
                          .clamp(0, 1),
                    ),
                    onRegionStartChanged: (value) =>
                        onChanged('regionStart', value),
                    onRegionEndChanged: (value) =>
                        onChanged('regionEnd', value),
                  )
                : _GrainCloudPreview(
                    position: livePosition,
                    size: device.grainSize,
                    density: device.density,
                    spray: device.spray,
                    pitch: device.grainPitch,
                  ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: controls,
        ),
      ],
    );
  }
}

void _paintText(Canvas canvas, String text, Offset anchor, Color color,
    double size, TextAlign align) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size)),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = switch (align) {
    TextAlign.center => anchor.dx - painter.width / 2,
    TextAlign.right => anchor.dx - painter.width,
    _ => anchor.dx,
  };
  painter.paint(canvas, Offset(dx, anchor.dy));
}
