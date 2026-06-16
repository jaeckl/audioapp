import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/engine_bridge.dart';
import '../features/arrangement/arrangement_view.dart';
import '../features/device_strip/device_strip.dart';
import '../features/transport/transport_bar.dart';

/// Placeholder DAW shell — timeline, transport, device strip (Milestone 00).
class DawShell extends StatefulWidget {
  const DawShell({super.key, required this.bridge});

  final EngineBridge bridge;

  @override
  State<DawShell> createState() => _DawShellState();
}

class _DawShellState extends State<DawShell> {
  bool _playing = false;
  String? _bridgeStatus;
  int? _selectedTrackIndex;

  @override
  void initState() {
    super.initState();
    _checkBridge();
  }

  Future<void> _checkBridge() async {
    try {
      final pong = await widget.bridge.ping();
      if (!mounted) return;
      setState(() => _bridgeStatus = pong.isNotEmpty ? 'Engine: $pong' : 'Engine: connected');
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _bridgeStatus = 'Engine: native bridge pending (M01)');
    } catch (e) {
      if (!mounted) return;
      setState(() => _bridgeStatus = 'Engine: $e');
    }
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await widget.bridge.stop();
    } else {
      await widget.bridge.play();
    }
    if (!mounted) return;
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_bridgeStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  _bridgeStatus!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ),
            Expanded(
              child: ArrangementView(
                selectedTrackIndex: _selectedTrackIndex,
                onTrackSelected: (i) => setState(() => _selectedTrackIndex = i),
              ),
            ),
            DeviceStrip(visible: _selectedTrackIndex != null),
            TransportBar(
              playing: _playing,
              bpm: 120,
              onPlayStop: _togglePlay,
            ),
          ],
        ),
      ),
    );
  }
}
