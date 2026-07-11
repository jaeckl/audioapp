import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_strip_metrics.dart';
import 'device_strip_theme.dart';
import 'stereo_gain_pan_panel.dart';

part 'device_strip_chrome_panels_routing_output_panel.dart';
part 'device_strip_chrome_panels_drum_mono_output_panel.dart';
part 'device_strip_chrome_panels_dynamics_input_panel.dart';
part 'device_strip_chrome_panels_dynamics_output_panel.dart';
part 'device_strip_chrome_panels_private_dynamics_side_column.dart';
part 'device_strip_chrome_panels_private_chrome_output_shell.dart';
part 'device_strip_chrome_panels_fx_output_panel.dart';
part 'device_strip_chrome_panels_private_chrome_input_shell.dart';
part 'device_strip_chrome_panels_synth_output_panel.dart';
part 'device_strip_chrome_panels_private_fx_toggle_button.dart';
part 'device_strip_chrome_panels_private_fx_button_adornment_painter.dart';

/// Right-edge chrome cap with no controls — mirrors the tool rail layout.
class EmptyChromeOutputPanel extends StatelessWidget {
  const EmptyChromeOutputPanel({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) =>
      _ChromeOutputShell(width: width, child: const SizedBox.shrink());
}

/// Passive right-edge cap for routing receivers, which have no output controls.
/// Mono drum output rail: gain + velocity sensitivity (no pan).
/// Dynamics FX input column (left of card): input meter + trim gain.
/// Dynamics FX output column: gain-reduction meter + output gain.
/// FX output panel: unified Mix + Width (replaces per-effect Mix knobs).
/// Synth output panel: gain/pan knobs + audio-fx / note-fx toggle buttons.
