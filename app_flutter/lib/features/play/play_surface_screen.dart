import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../arrangement/arrangement_view.dart';
import 'mpc_pad_grid.dart';
import 'octave_panel.dart';
import 'perform_panel.dart';
import 'play_deck_layout.dart';
import 'play_deck_rail.dart';
import 'play_deck_theme.dart';
import 'play_keyboard.dart';
import 'play_scale.dart';

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
  PlaySurfaceMode _surfaceMode = PlaySurfaceMode.pads;
  PlayContextView _view = PlayContextView.perform;
  int _octaveOffset = 0;
  int _keyboardRows = 2;
  int _padBank = 0;
  String _scaleId = PlayScale.major.id;
  bool _inKeyOnly = true;
  bool _busy = false;

  ChordQuality _chord = ChordQuality.major;
  ArpMode _arp = ArpMode.off;
  int _octaveSpan = 1;
  int _rateMs = 130;
  int _activeRootOffset = 0;
  final Set<int> _highlightedPitches = {};

  static const int _rootMidi = 60;
  static const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

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
    if (track?.oscillatorDevice != null) {
      _surfaceMode = PlaySurfaceMode.keys;
    } else if (track?.samplerDevice != null) {
      _surfaceMode = PlaySurfaceMode.pads;
    }
  }

  void _onOctaveDelta(int delta) {
    setState(() {
      _octaveOffset = (_octaveOffset + delta).clamp(-4, 4);
      if (_surfaceMode == PlaySurfaceMode.pads) {
        final bank = ((_octaveOffset + 4) ~/ 2).clamp(0, 3);
        _padBank = bank * 16;
      }
    });
  }

  void _onSurfaceModeChanged(PlaySurfaceMode mode) {
    setState(() {
      _surfaceMode = mode;
      _view = PlayContextView.perform;
      _highlightedPitches.clear();
    });
  }

  void _onViewChanged(PlayContextView view) {
    setState(() {
      _view = view;
      if (view != PlayContextView.performPanel) {
        _highlightedPitches.clear();
      }
    });
  }

  void _updateHighlights(int rootOffset) {
    _activeRootOffset = rootOffset;
    if (_chord == ChordQuality.off) {
      _highlightedPitches
        ..clear()
        ..add(_rootMidi + _octaveOffset * 12 + rootOffset);
      return;
    }
    final root = _rootMidi + _octaveOffset * 12 + rootOffset;
    _highlightedPitches
      ..clear()
      ..addAll(_buildChordPitches(root, _chord, _octaveSpan));
  }

  static List<int> _buildChordPitches(int root, ChordQuality q, int span) {
    final intervals = q.intervals;
    return [
      for (var o = 0; o < span; o++)
        for (final step in intervals) root + o * 12 + step,
    ];
  }

  Future<void> _setRecordArmed() async {
    try {
      final updated = await widget.bridge.setRecordArmed(!widget.snapshot.recordArmed);
      await widget.onSnapshot(updated);
    } catch (_) {}
  }

  Future<void> _commitCapture() async {
    if (_busy) return;
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
    final armed = widget.snapshot.recordArmed;
    final scale = PlayScale.byId(_scaleId);
    final hasTrack = track != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTrack)
          _CaptureStrip(
            armed: armed,
            busy: _busy,
            onArmToggle: _setRecordArmed,
            onCapture: _commitCapture,
            onClear: _clearCapture,
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
        ColoredBox(
          color: PlayDeckTheme.deckBackground,
          child: SizedBox(
            height: PlayDeckLayout.deckHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlayDeckRail(
                  surfaceMode: _surfaceMode,
                  activeView: _view,
                  octaveDisplay: _octaveDisplay,
                  enabled: hasTrack,
                  onSurfaceModeChanged: _onSurfaceModeChanged,
                  onViewChanged: _onViewChanged,
                ),
                Expanded(child: _buildContextArea(hasTrack, scale)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextArea(bool hasTrack, PlayScale scale) {
    if (!hasTrack) {
      return ColoredBox(
        color: PlayDeckTheme.gapColor,
        child: Center(
          child: Text(
            'Select a track',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: PlayDeckTheme.railLabel),
          ),
        ),
      );
    }

    switch (_view) {
      case PlayContextView.octave:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: OctavePanel(
              octaveOffset: _octaveOffset,
              rowCount: _keyboardRows,
              scaleId: _scaleId,
              inKeyOnly: _inKeyOnly,
              rootName: _noteNames[_rootMidi % 12],
              onOctaveDelta: _onOctaveDelta,
              onRowCountChanged: (r) => setState(() => _keyboardRows = r),
              onScaleChanged: (id) => setState(() => _scaleId = id),
              onInKeyToggle: () => setState(() => _inKeyOnly = !_inKeyOnly),
            ),
          ),
        );
      case PlayContextView.performPanel:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: PerformPanel(
              bridge: widget.bridge,
              scaleId: _scaleId,
              rootMidi: _rootMidi + _octaveOffset * 12,
              chord: _chord,
              arp: _arp,
              octaveSpan: _octaveSpan,
              rateMs: _rateMs,
              highlightedRoot: _activeRootOffset,
              onChordChanged: (q) => setState(() {
                _chord = q;
                _updateHighlights(_activeRootOffset);
              }),
              onArpChanged: (m) => setState(() => _arp = m),
              onSpanChanged: (s) => setState(() {
                _octaveSpan = s;
                _updateHighlights(_activeRootOffset);
              }),
              onRateChanged: (ms) => setState(() => _rateMs = ms),
              onKeyDown: (offset) => setState(() => _updateHighlights(offset)),
              onKeyUp: () => setState(() => _highlightedPitches.clear()),
            ),
          ),
        );
      case PlayContextView.perform:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
            child: _surfaceMode == PlaySurfaceMode.pads
                ? MpcPadGrid(
                    bridge: widget.bridge,
                    bankOffset: _padBank,
                    highlightedPitches: _highlightedPitches,
                  )
                : PlayKeyboard(
                    bridge: widget.bridge,
                    scale: scale,
                    inKeyOnly: _inKeyOnly && scale.id != 'chromatic',
                    octaveOffset: _octaveOffset,
                    rowCount: _keyboardRows,
                    highlightedPitches: _highlightedPitches,
                  ),
          ),
        );
    }
  }

  int get _octaveDisplay => (2 + _octaveOffset).clamp(-2, 8);
}

/// Slim capture bar above the arrangement when ARM is on. Hidden when not armed.
class _CaptureStrip extends StatelessWidget {
  const _CaptureStrip({
    required this.armed,
    required this.busy,
    required this.onArmToggle,
    required this.onCapture,
    required this.onClear,
  });

  final bool armed;
  final bool busy;
  final VoidCallback onArmToggle;
  final VoidCallback onCapture;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!armed) {
      return _SimpleTextButton(
        icon: Icons.fiber_manual_record,
        color: Colors.redAccent,
        label: 'ARM',
        onTap: onArmToggle,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
