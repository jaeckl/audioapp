import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bridge/project_snapshot.dart';
import 'midi_comp_tool.dart';
import 'piano_roll_theme.dart';

/// One-time SnackBar hints when the user first selects each comp dock mode.
abstract final class MidiCompModeHints {
  static const _prefix = 'midi_comp_hint_v2_';

  static Future<void> maybeShow(BuildContext context, MidiCompTool tool) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${tool.name}';
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    if (!context.mounted) return;
    final message = switch (tool) {
      MidiCompTool.comp =>
        'Comp — drag markers and tap take lanes to assign regions',
      MidiCompTool.markers =>
        'Split — insert markers at playhead, CUT or RING boundaries',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: PianoRollTheme.dockBackground,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Shows which take owns the region under the playhead (Comp mode).
class MidiCompRegionBar extends StatelessWidget {
  const MidiCompRegionBar({
    super.key,
    required this.playheadBeat,
    required this.takes,
    required this.regions,
  });

  final double playheadBeat;
  final List<MidiClipTakeSnapshot> takes;
  final List<MidiClipTakeRegionSnapshot> regions;

  static const barHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    final region = _regionAtBeat(playheadBeat);
    final takeName = region == null ? '—' : _takeName(region.takeId);
    return ColoredBox(
      color: PianoRollTheme.background,
      child: SizedBox(
        height: barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.layers,
                size: 16,
                color: const Color(0xFFFF6D8A).withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Region at ${playheadBeat.toStringAsFixed(2)}b uses $takeName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PianoRollTheme.labelMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Text(
                'Tap lane to comp',
                style: TextStyle(
                  color: PianoRollTheme.labelMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MidiClipTakeRegionSnapshot? _regionAtBeat(double beat) {
    for (var i = 0; i < regions.length; i++) {
      final region = regions[i];
      final isLast = i == regions.length - 1;
      if (beat >= region.startBeat &&
          (beat < region.endBeat || (isLast && beat <= region.endBeat))) {
        return region;
      }
    }
    return null;
  }

  String _takeName(String takeId) {
    for (final take in takes) {
      if (take.id == takeId) return take.name;
    }
    return 'Take ?';
  }
}
