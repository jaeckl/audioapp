import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'play_deck_theme.dart';

/// Autochord + arpeggiator view. Plays live via the bridge while held.
class PerformPanel extends StatefulWidget {
  const PerformPanel({
    super.key,
    required this.bridge,
    required this.scaleId,
    required this.rootMidi,
    required this.chord,
    required this.arp,
    required this.octaveSpan,
    required this.rateMs,
    required this.highlightedRoot,
    required this.onChordChanged,
    required this.onArpChanged,
    required this.onSpanChanged,
    required this.onRateChanged,
    required this.onKeyDown,
    required this.onKeyUp,
  });

  final EngineBridge bridge;
  final String scaleId;
  final int rootMidi;
  final ChordQuality chord;
  final ArpMode arp;
  final int octaveSpan;
  final int rateMs;
  final int highlightedRoot;
  final ValueChanged<ChordQuality> onChordChanged;
  final ValueChanged<ArpMode> onArpChanged;
  final ValueChanged<int> onSpanChanged;
  final ValueChanged<int> onRateChanged;
  final ValueChanged<int> onKeyDown;
  final VoidCallback onKeyUp;

  @override
  State<PerformPanel> createState() => _PerformPanelState();
}

class _PerformPanelState extends State<PerformPanel> {
  final Set<int> _activeNotes = {};
  Timer? _arpTimer;
  int _arpIndex = 0;
  int _arpDir = 1;

  static const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  @override
  void dispose() {
    _arpTimer?.cancel();
    _releaseAll();
    super.dispose();
  }

  Future<void> _releaseAll() async {
    final pitches = List<int>.from(_activeNotes);
    _activeNotes.clear();
    for (final p in pitches) {
      try {
        await widget.bridge.noteOff(pitch: p);
      } catch (_) {}
    }
  }

  List<int> _chordPitches(int root) {
    final intervals = widget.chord.intervals;
    return [
      for (var o = 0; o < widget.octaveSpan; o++)
        for (final step in intervals) root + o * 12 + step,
    ];
  }

  Future<void> _playChord(int root) async {
    await _releaseAll();
    final pitches = _chordPitches(root);
    for (final pitch in pitches) {
      _activeNotes.add(pitch);
      try {
        await widget.bridge.noteOn(pitch: pitch, velocity: 90);
      } catch (_) {}
    }
  }

  void _startArp(List<int> pitches) {
    _arpTimer?.cancel();
    if (widget.arp == ArpMode.off || pitches.isEmpty) {
      _playChord(widget.rootMidi + widget.highlightedRoot * 12);
      return;
    }
    _arpIndex = 0;
    _arpDir = 1;
    _playArpStep(pitches);
    _arpTimer = Timer.periodic(Duration(milliseconds: widget.rateMs), (_) {
      if (widget.arp == ArpMode.off) {
        _arpTimer?.cancel();
        return;
      }
      _arpIndex = _nextArpIndex(widget.arp, pitches.length, _arpIndex, _arpDir);
      final shouldFlip = (widget.arp == ArpMode.upDown && (_arpIndex == pitches.length - 1 || _arpIndex == 0)) ||
          (widget.arp == ArpMode.downUp && (_arpIndex == 0 || _arpIndex == pitches.length - 1));
      if (shouldFlip) {
        _arpDir *= -1;
      }
      _playArpStep(pitches);
    });
  }

  int _nextArpIndex(ArpMode mode, int count, int index, int direction) {
    switch (mode) {
      case ArpMode.up:
        return (index + 1) % count;
      case ArpMode.down:
        return (index - 1 + count) % count;
      case ArpMode.upDown:
      case ArpMode.downUp:
        final next = index + direction;
        if (next < 0 || next >= count) {
          return (index - direction).clamp(0, count - 1);
        }
        return next;
      case ArpMode.random:
        return (index + 1) % count;
      case ArpMode.chord:
      case ArpMode.strum:
        return 0;
      case ArpMode.off:
        return 0;
    }
  }

  Future<void> _playArpStep(List<int> pitches) async {
    final pitch = pitches[_arpIndex];
    try {
      await widget.bridge.noteOff(pitch: pitch);
      await widget.bridge.noteOn(pitch: pitch, velocity: 90);
    } catch (_) {}
  }

  Future<void> _strum(List<int> pitches, {int stepMs = 30}) async {
    await _releaseAll();
    for (final p in pitches) {
      _activeNotes.add(p);
      try {
        await widget.bridge.noteOn(pitch: p, velocity: 90);
      } catch (_) {}
      await Future.delayed(Duration(milliseconds: stepMs));
    }
  }

  void _onKeyDown(int rootOffset) {
    widget.onKeyDown(rootOffset);
    final root = widget.rootMidi + rootOffset;
    if (widget.chord == ChordQuality.off) {
      _playSingle(root);
      return;
    }
    final pitches = _chordPitches(root);
    if (widget.arp == ArpMode.off || widget.arp == ArpMode.chord) {
      _playChord(root);
      return;
    }
    if (widget.arp == ArpMode.strum) {
      _strum(pitches);
      return;
    }
    _startArp(pitches);
  }

  Future<void> _playSingle(int root) async {
    await _releaseAll();
    _activeNotes.add(root);
    try {
      await widget.bridge.noteOn(pitch: root, velocity: 90);
    } catch (_) {}
  }

  void _onKeyUp() {
    _arpTimer?.cancel();
    _releaseAll();
    widget.onKeyUp();
  }

  String _keyName(int root) => _noteNames[root % 12];

  String get _helpLine {
    if (widget.chord == ChordQuality.off) {
      return 'Press to play a single note from the current scale/region.';
    }
    if (widget.arp == ArpMode.off || widget.arp == ArpMode.chord) {
      return 'Hold to play the full chord. Lift to release.';
    }
    if (widget.arp == ArpMode.strum) {
      return 'Press to strum the chord. Lift to release.';
    }
    return 'Press to start the arpeggio. Lift to release.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: PlayDeckTheme.panelBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          const _SectionTitle(text: 'Chord'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final q in ChordQuality.values)
                _Pill(
                  label: q.label,
                  selected: widget.chord == q,
                  onTap: () => widget.onChordChanged(q),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionTitle(text: 'Arpeggiator'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in ArpMode.values)
                _Pill(
                  label: m.label,
                  selected: widget.arp == m,
                  onTap: () => widget.onArpChanged(m),
                ),
            ],
          ),
          if (widget.arp != ArpMode.off) ...[
            const SizedBox(height: 10),
            _SliderRow(
              label: 'Rate',
              value: widget.rateMs.toDouble(),
              min: 60,
              max: 400,
              trailing: '${widget.rateMs}ms',
              onChanged: (v) => widget.onRateChanged(v.round()),
            ),
          ],
          const SizedBox(height: 14),
          const _SectionTitle(text: 'Range'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var o = 1; o <= 3; o++)
                _Pill(
                  label: '${o}oct',
                  selected: widget.octaveSpan == o,
                  onTap: () => widget.onSpanChanged(o),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionTitle(text: 'Hold a key'),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _helpLine,
              style: theme.textTheme.bodySmall?.copyWith(color: PlayDeckTheme.railLabel),
            ),
          ),
          const SizedBox(height: 10),
          _KeyRow(
            rootMidi: widget.rootMidi,
            activeOffset: widget.highlightedRoot,
            onDown: _onKeyDown,
            onUp: _onKeyUp,
            labelFor: _keyName,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          color: PlayDeckTheme.railLabel,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PlayDeckTheme.optionActive : PlayDeckTheme.optionIdle,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.black : PlayDeckTheme.optionLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.trailing,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final String trailing;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label,
              style: const TextStyle(fontSize: 11, color: PlayDeckTheme.railLabel)),
        ),
        Expanded(
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(trailing,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: PlayDeckTheme.railLabel)),
        ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.rootMidi,
    required this.activeOffset,
    required this.onDown,
    required this.onUp,
    required this.labelFor,
  });

  final int rootMidi;
  final int activeOffset;
  final void Function(int rootOffset) onDown;
  final VoidCallback onUp;
  final String Function(int root) labelFor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var offset = -1; offset <= 1; offset++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => onDown(offset * 12),
                onPointerUp: (_) => onUp(),
                onPointerCancel: (_) => onUp(),
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: offset == activeOffset
                          ? PlayDeckTheme.padActive
                          : PlayDeckTheme.padIdle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      labelFor(rootMidi + offset * 12),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PlayDeckTheme.optionLabel,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
