import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bridge/project_snapshot.dart';
import 'midi_comp_tool.dart';
import 'midi_take_color.dart';
import 'piano_roll_theme.dart';

part 'midi_comp_mode_hints_midi_comp_region_bar.dart';
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
