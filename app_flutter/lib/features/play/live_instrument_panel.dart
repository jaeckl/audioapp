import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../../app/record_write_mode.dart';
import 'play_deck.dart';
import 'play_deck_layout.dart';

/// On-screen piano / pads panel shown below the arrangement timeline.
class LiveInstrumentPanel extends StatefulWidget {
  const LiveInstrumentPanel({
    super.key,
    required this.bridge,
    required this.snapshot,
    required this.onRecordArmed,
    required this.recordWriteMode,
    required this.onRecordWriteModeChanged,
  });

  final EngineBridge bridge;
  final ProjectSnapshot snapshot;
  final Future<void> Function(bool armed) onRecordArmed;
  final RecordWriteMode recordWriteMode;
  final ValueChanged<RecordWriteMode> onRecordWriteModeChanged;

  @override
  State<LiveInstrumentPanel> createState() => _LiveInstrumentPanelState();
}

class _LiveInstrumentPanelState extends State<LiveInstrumentPanel> {
  GlobalKey<PlayDeckState> _deckKey = GlobalKey();
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
            recordWriteMode: widget.recordWriteMode,
            quantize: deck?.quantize ?? CaptureQuantize.quarter,
            latch: deck?.latch ?? false,
            metronome: deck?.metronome ?? false,
            onArmToggle: () => _setRecordArmed(!armed),
            onRecordWriteModeChanged: widget.onRecordWriteModeChanged,
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
    required this.recordWriteMode,
    required this.quantize,
    required this.latch,
    required this.metronome,
    required this.onArmToggle,
    required this.onRecordWriteModeChanged,
    required this.onLatchToggle,
    required this.onMetronomeToggle,
  });

  final bool armed;
  final RecordWriteMode recordWriteMode;
  final CaptureQuantize quantize;
  final bool latch;
  final bool metronome;
  final VoidCallback onArmToggle;
  final ValueChanged<RecordWriteMode> onRecordWriteModeChanged;
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
              child: _RecordModeSelector(
                mode: recordWriteMode,
                onChanged: onRecordWriteModeChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordModeSelector extends StatelessWidget {
  const _RecordModeSelector({
    required this.mode,
    required this.onChanged,
  });

  final RecordWriteMode mode;
  final ValueChanged<RecordWriteMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RecordWriteMode>(
      tooltip: 'Record mode',
      initialValue: mode,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final value in RecordWriteMode.values)
          PopupMenuItem(value: value, child: Text(value.label)),
      ],
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF5A2A30))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fiber_smart_record,
                size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              mode.label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white54),
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
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
