import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import 'play_deck.dart';
import 'play_deck_layout.dart';

/// On-screen piano / pads panel shown below the arrangement timeline.
class LiveInstrumentPanel extends StatefulWidget {
  const LiveInstrumentPanel({
    super.key,
    required this.bridge,
    required this.snapshot,
    required this.onSnapshot,
    required this.onRecordArmed,
  });

  final EngineBridge bridge;
  final ProjectSnapshot snapshot;
  final Future<void> Function(ProjectSnapshot snapshot) onSnapshot;
  final Future<void> Function(bool armed) onRecordArmed;

  @override
  State<LiveInstrumentPanel> createState() => _LiveInstrumentPanelState();
}

class _LiveInstrumentPanelState extends State<LiveInstrumentPanel> {
  GlobalKey<PlayDeckState> _deckKey = GlobalKey();
  bool _busy = false;

  PlaySurfaceMode? _preferredSurfaceMode;

  @override
  void initState() {
    super.initState();
    _syncModeFromTrack();
  }

  @override
  void didUpdateWidget(covariant LiveInstrumentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.selectedTrackId != widget.snapshot.selectedTrackId) {
      _deckKey = GlobalKey();
      _syncModeFromTrack();
      setState(() {});
    }
  }

  void _syncModeFromTrack() {
    final track = widget.snapshot.selectedTrack;
    PlaySurfaceMode? mode;
    if (track?.oscillatorDevice != null) {
      mode = PlaySurfaceMode.keys;
    } else if (track?.samplerDevice != null) {
      mode = PlaySurfaceMode.pads;
    }
    if (mode != _preferredSurfaceMode) {
      setState(() => _preferredSurfaceMode = mode);
      _deckKey.currentState?.setSurfaceMode(mode ?? PlaySurfaceMode.pads);
    }
  }

  Future<void> _setRecordArmed(bool armed) async {
    try {
      await widget.onRecordArmed(armed);
    } catch (_) {}
  }

  Future<void> _commitCapture() async {
    if (_busy) return;
    final deck = _deckKey.currentState;
    if (deck == null) return;
    if (deck.quantize != CaptureQuantize.off) {
      deck.setMetronome(true);
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      deck.setMetronome(false);
      setState(() {});
    }
    setState(() => _busy = true);
    try {
      final updated = await widget.bridge.commitCapture();
      await widget.onSnapshot(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Captured to MIDI clip at playhead')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearCapture() async {
    try {
      await widget.bridge.clearCapture();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.snapshot.selectedTrack;
    final hasTrack = track != null;
    final armed = widget.snapshot.recordArmed;
    final deck = _deckKey.currentState;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTrack)
          _CaptureStrip(
            armed: armed,
            busy: _busy,
            quantize: deck?.quantize ?? CaptureQuantize.quarter,
            latch: deck?.latch ?? false,
            metronome: deck?.metronome ?? false,
            onArmToggle: () => _setRecordArmed(!armed),
            onCapture: _commitCapture,
            onClear: _clearCapture,
            onLatchToggle: () {
              _deckKey.currentState?.toggleLatch();
              setState(() {});
            },
            onMetronomeToggle: () {
              _deckKey.currentState?.toggleMetronome();
              setState(() {});
            },
          ),
        PlayDeck(
          key: _deckKey,
          bridge: widget.bridge,
          enabled: hasTrack,
          showModStrip: hasTrack,
          initialSurfaceMode: _preferredSurfaceMode,
          padPitchBase: track?.drumAnchorPitch,
          onPerformanceChanged: () => setState(() {}),
        ),
      ],
    );
  }
}

class _CaptureStrip extends StatelessWidget {
  const _CaptureStrip({
    required this.armed,
    required this.busy,
    required this.quantize,
    required this.latch,
    required this.metronome,
    required this.onArmToggle,
    required this.onCapture,
    required this.onClear,
    required this.onLatchToggle,
    required this.onMetronomeToggle,
  });

  final bool armed;
  final bool busy;
  final CaptureQuantize quantize;
  final bool latch;
  final bool metronome;
  final VoidCallback onArmToggle;
  final VoidCallback onCapture;
  final VoidCallback onClear;
  final VoidCallback onLatchToggle;
  final VoidCallback onMetronomeToggle;

  @override
  Widget build(BuildContext context) {
    if (!armed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            _SimpleTextButton(
              icon: Icons.fiber_manual_record,
              color: Colors.redAccent,
              label: 'ARM',
              onTap: onArmToggle,
            ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFF2A1A1E),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            _SimpleTextButton(
              icon: Icons.fiber_manual_record,
              color: Colors.redAccent,
              label: 'ARMED',
              onTap: onArmToggle,
            ),
            const VerticalDivider(width: 1, color: Color(0xFF5A2A30)),
            _SimpleTextButton(
              icon: latch ? Icons.lock : Icons.lock_open,
              color: latch ? Colors.amber : Colors.white54,
              label: 'Latch',
              onTap: onLatchToggle,
            ),
            _SimpleTextButton(
              icon: metronome ? Icons.timer : Icons.timer_outlined,
              color: metronome ? Colors.amber : Colors.white54,
              label: quantize.label,
              onTap: onMetronomeToggle,
            ),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB0414E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: busy ? null : onCapture,
                icon: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('Capture'),
              ),
            ),
            _SimpleTextButton(
              icon: Icons.close,
              color: Colors.white70,
              label: 'Clear',
              onTap: onClear,
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleTextButton extends StatelessWidget {
  const _SimpleTextButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
