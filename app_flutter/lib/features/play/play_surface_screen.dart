import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../arrangement/arrangement_view.dart';
import 'play_deck.dart';
import 'play_deck_layout.dart';
import 'track_mute_row.dart';

class PlaySurfaceScreen extends StatefulWidget {
  const PlaySurfaceScreen({
    super.key,
    required this.bridge,
    required this.snapshot,
    required this.onSnapshot,
    required this.playing,
    required this.onPlayStop,
    required this.onPlayheadSeek,
    required this.onTrackSelected,
    required this.onAddMidiClip,
    required this.onAddAudioClip,
    required this.onClipTap,
    required this.onSampleClipTap,
    required this.onMoveClip,
    this.onDeleteClip,
    this.onDuplicateClip,
  });

  final EngineBridge bridge;
  final ProjectSnapshot snapshot;
  final Future<void> Function(ProjectSnapshot snapshot) onSnapshot;
  final bool playing;
  final VoidCallback onPlayStop;
  final ValueChanged<double> onPlayheadSeek;
  final ValueChanged<String> onTrackSelected;
  final void Function(String trackId, double startBeat) onAddMidiClip;
  final void Function(String trackId, double desiredStartBeat) onAddAudioClip;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;
  final Future<void> Function({
    required String clipId,
    required String trackId,
    required double startBeat,
  }) onMoveClip;
  final void Function(String clipId)? onDeleteClip;
  final void Function(String clipId)? onDuplicateClip;

  @override
  State<PlaySurfaceScreen> createState() => _PlaySurfaceScreenState();
}

class _PlaySurfaceScreenState extends State<PlaySurfaceScreen> {
  final GlobalKey<PlayDeckState> _deckKey = GlobalKey();
  bool _busy = false;

  final Set<String> _mutedTrackIds = {};
  final Set<String> _soloedTrackIds = {};

  PlaySurfaceMode? _preferredSurfaceMode;

  @override
  void initState() {
    super.initState();
    _syncModeFromTrack();
    widget.bridge.enterPlayMode();
  }

  @override
  void didUpdateWidget(covariant PlaySurfaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.selectedTrackId != widget.snapshot.selectedTrackId) {
      _syncModeFromTrack();
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

  Future<void> _setRecordArmed() async {
    try {
      final updated = await widget.bridge.setRecordArmed(!widget.snapshot.recordArmed);
      await widget.onSnapshot(updated);
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

  void _toggleTrackMute(String trackId) {
    setState(() {
      if (_mutedTrackIds.contains(trackId)) {
        _mutedTrackIds.remove(trackId);
      } else {
        _mutedTrackIds.add(trackId);
      }
    });
  }

  void _toggleTrackSolo(String trackId) {
    setState(() {
      if (_soloedTrackIds.contains(trackId)) {
        _soloedTrackIds.remove(trackId);
      } else {
        _soloedTrackIds.add(trackId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.snapshot.selectedTrack;
    final armed = widget.snapshot.recordArmed;
    final hasTrack = track != null;
    final deck = _deckKey.currentState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTrack)
          _CaptureStrip(
            armed: armed,
            busy: _busy,
            quantize: deck?.quantize ?? CaptureQuantize.quarter,
            latch: deck?.latch ?? false,
            metronome: deck?.metronome ?? false,
            onArmToggle: _setRecordArmed,
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
        Expanded(
          child: ArrangementView(
            snapshot: widget.snapshot,
            compact: true,
            focusTrackId: widget.snapshot.selectedTrackId,
            playheadBeats: widget.snapshot.playheadBeats,
            playing: widget.playing,
            onPlayStop: widget.onPlayStop,
            onPlayheadSeek: widget.onPlayheadSeek,
            onTrackSelected: widget.onTrackSelected,
            onAddTrack: () {},
            onAddMidiClip: widget.onAddMidiClip,
            onAddAudioClip: widget.onAddAudioClip,
            onClipTap: widget.onClipTap,
            onSampleClipTap: widget.onSampleClipTap,
            onMoveClip: widget.onMoveClip,
            onDeleteClip: widget.onDeleteClip,
            onDuplicateClip: widget.onDuplicateClip,
          ),
        ),
        if (hasTrack)
          TrackMuteRow(
            tracks: widget.snapshot.tracks,
            selectedTrackId: widget.snapshot.selectedTrackId,
            mutedTrackIds: _mutedTrackIds,
            soloedTrackIds: _soloedTrackIds,
            onToggleMute: _toggleTrackMute,
            onToggleSolo: _toggleTrackSolo,
            onSelectTrack: widget.onTrackSelected,
          ),
        PlayDeck(
          key: _deckKey,
          bridge: widget.bridge,
          enabled: hasTrack,
          showModStrip: hasTrack,
          initialSurfaceMode: _preferredSurfaceMode,
          onPerformanceChanged: () => setState(() {}),
        ),
      ],
    );
  }
}

/// Slim capture bar above the arrangement when ARM is on. Hidden when not armed.
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
