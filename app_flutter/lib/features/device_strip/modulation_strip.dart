import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_theme.dart';
import 'modulator_types.dart';

part 'modulation_strip_lfo_card.dart';
part 'modulation_strip_lfo_card_state.dart';
part 'modulation_strip_lfo_compact_row.dart';
part 'modulation_strip_expanded_lfo_content.dart';
part 'modulation_strip_mini_slider.dart';

/// Collapsible modulation strip that sits below the device header.
/// Shows LFO cards with waveform/rate/sync controls and a target list.
class ModulationStrip extends StatelessWidget {
  const ModulationStrip({
    super.key,
    required this.lfos,
    required this.modEdges,
    required this.deviceId,
    required this.onBridgeCall,
    this.maxLfos = ModulatorTypes.maxCount,
  });

  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final String deviceId;
  final Future<ProjectSnapshot> Function(
      String method, Map<String, dynamic> args) onBridgeCall;
  final int maxLfos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DeviceStripTheme.toolRailBackground,
        border: Border(
          left: BorderSide(
              color: DeviceStripTheme.cardBorder,
              width: DeviceStripTheme.cardBorderWidth),
          right: BorderSide(
              color: DeviceStripTheme.cardBorder,
              width: DeviceStripTheme.cardBorderWidth),
          bottom: BorderSide(
              color: DeviceStripTheme.cardBorder,
              width: DeviceStripTheme.cardBorderWidth),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...lfos.map((lfo) => _LfoCard(
                  lfo: lfo,
                  edges: modEdges
                      .where((e) => e.lfoId == lfo.id && e.deviceId == deviceId)
                      .toList(),
                  onBridgeCall: onBridgeCall,
                  deviceId: deviceId,
                )),
            if (lfos.length < maxLfos)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => onBridgeCall(
                      'createLfo',
                      {'deviceId': deviceId},
                    ),
                    icon: Icon(Icons.add,
                        size: 14, color: theme.colorScheme.primary),
                    label: Text(
                      'Add Modulator',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact horizontal slider for LFO rate/phase.
