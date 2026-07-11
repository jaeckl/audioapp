import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import 'device_landscape_shell.dart';
import 'device_strip_metrics.dart';
import 'phase_mod_synth_device_panel.dart';

part 'phase_mod_synth_editor_screen_phase_mod_synth_editor_screen_state.dart';

/// Fullscreen phase modulation synth editor with hold-to-test note.
class PhaseModSynthEditorScreen extends StatefulWidget {
  const PhaseModSynthEditorScreen({
    super.key,
    required this.trackName,
    required this.device,
    required this.bridge,
    required this.onParameterChanged,
  });

  final String trackName;
  final PhaseModSynthDeviceSnapshot device;
  final EngineBridge bridge;
  final Future<void> Function(String parameterId, double value)
      onParameterChanged;

  @override
  State<PhaseModSynthEditorScreen> createState() =>
      _PhaseModSynthEditorScreenState();
}
