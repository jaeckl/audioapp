import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import 'device_landscape_shell.dart';
import 'device_strip_metrics.dart';
import 'subtractive_synth_device_panel.dart';

part 'subtractive_synth_editor_screen_subtractive_synth_editor_screen_state.dart';

/// Fullscreen subtractive synth editor with hold-to-test note.
class SubtractiveSynthEditorScreen extends StatefulWidget {
  const SubtractiveSynthEditorScreen({
    super.key,
    required this.trackName,
    required this.device,
    required this.bridge,
    required this.onParameterChanged,
  });

  final String trackName;
  final SubtractiveSynthDeviceSnapshot device;
  final EngineBridge bridge;
  final Future<void> Function(String parameterId, double value)
      onParameterChanged;

  @override
  State<SubtractiveSynthEditorScreen> createState() =>
      _SubtractiveSynthEditorScreenState();
}
