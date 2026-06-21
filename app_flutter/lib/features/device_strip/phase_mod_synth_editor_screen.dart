import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import 'device_landscape_shell.dart';
import 'device_strip_metrics.dart';
import 'phase_mod_synth_device_panel.dart';

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
  final Future<void> Function(String parameterId, double value) onParameterChanged;

  @override
  State<PhaseModSynthEditorScreen> createState() => _PhaseModSynthEditorScreenState();
}

class _PhaseModSynthEditorScreenState extends State<PhaseModSynthEditorScreen> {
  late PhaseModSynthDeviceSnapshot _device;
  PhaseModSynthDeviceTab _tab = PhaseModSynthDeviceTab.mix;
  bool _testNoteHeld = false;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
  }

  Future<void> _handleParameter(String id, double value) async {
    setState(() => _device = _device.withParameter(id, value));
    await widget.onParameterChanged(id, value);
  }

  Future<void> _testNoteDown() async {
    if (_testNoteHeld) return;
    _testNoteHeld = true;
    await widget.bridge.noteOn(pitch: 60, velocity: 100);
  }

  Future<void> _testNoteUp() async {
    if (!_testNoteHeld) return;
    _testNoteHeld = false;
    await widget.bridge.noteOff(pitch: 60);
  }

  @override
  void dispose() {
    if (_testNoteHeld) {
      widget.bridge.noteOff(pitch: 60);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DeviceLandscapeShell(
      title: '${widget.trackName} · Phase Mod Synth',
      designWidth: DeviceStripMetrics.phaseModSynthDesignWidth,
      designHeight: DeviceStripMetrics.height + 48,
      actions: [
        GestureDetector(
          onTapDown: (_) => _testNoteDown(),
          onTapUp: (_) => _testNoteUp(),
          onTapCancel: () => _testNoteUp(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _testNoteHeld
                  ? PhaseModSynthDevicePanel.accent
                  : const Color(0xFF2A2A34),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Test C4',
              style: TextStyle(
                color: _testNoteHeld ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
      child: PhaseModSynthDevicePanel(
        device: _device,
        onParameterChanged: (id, v) => _handleParameter(id, v),
        density: PhaseModSynthPanelDensity.editor,
        selectedTab: _tab,
        onTabChanged: (t) => setState(() => _tab = t),
      ),
    );
  }
}