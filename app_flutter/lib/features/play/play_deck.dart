import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'mod_strip.dart';
import 'mpc_pad_grid.dart';
import 'octave_panel.dart';
import 'perform_panel.dart';
import 'performance_panel.dart';
import 'play_deck_layout.dart';
import 'play_deck_rail.dart';
import 'play_deck_theme.dart';
import 'play_keyboard.dart';
import 'play_scale.dart';
import 'scale_builder_panel.dart';

/// Shared play surface: rail (Pads/Keys · Octave · Perform · Perf), mod strip,
/// and context panels — used in Play tab and piano roll editor.
class PlayDeck extends StatefulWidget {
  const PlayDeck({
    super.key,
    required this.bridge,
    this.enabled = true,
    this.showModStrip = true,
    this.initialSurfaceMode,
    this.initialOctaveOffset = 0,
    this.padPitchBase,
    this.onPerformanceChanged,
  });

  final EngineBridge bridge;
  final bool enabled;
  final bool showModStrip;
  final PlaySurfaceMode? initialSurfaceMode;
  final int initialOctaveOffset;
  /// When set (drum tracks), pad 0 fires this MIDI note instead of C3 (48).
  final int? padPitchBase;
  final VoidCallback? onPerformanceChanged;

  @override
  State<PlayDeck> createState() => PlayDeckState();
}

class PlayDeckState extends State<PlayDeck> {
  late PlaySurfaceMode _surfaceMode;
  PlayContextView _view = PlayContextView.perform;
  late int _octaveOffset;
  int _keyboardRows = PlayDeckLayout.defaultKeyboardRows;
  int _padBank = 0;
  String _scaleId = PlayScale.major.id;
  bool _inKeyOnly = true;

  ChordQuality _chord = ChordQuality.major;
  ArpMode _arp = ArpMode.off;
  int _octaveSpan = 1;
  int _rateMs = 130;
  int _activeRootOffset = 0;
  final Set<int> _highlightedPitches = {};

  VelocityCurve _velocityCurve = VelocityCurve.linear;
  CaptureQuantize _quantize = CaptureQuantize.quarter;
  bool _padChokeByColumn = true;
  bool _padChokeByRow = false;

  bool _latch = false;
  bool _sustain = false;
  bool _repeat = false;
  bool _metronome = false;
  List<ChordMemory> _chordMemory = [
    ChordMemory(label: 'Maj', quality: ChordQuality.major),
    ChordMemory(label: 'Min', quality: ChordQuality.minor),
    ChordMemory(label: '7', quality: ChordQuality.seventh),
    ChordMemory(label: 'm7', quality: ChordQuality.minor7),
  ];

  final List<PlayScale> _customScales = [];

  double _modulation = 0.0;
  double _pitchBend = 0.0;

  static const int _rootMidi = 60;
  static const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  bool get latch => _latch;
  bool get metronome => _metronome;
  CaptureQuantize get quantize => _quantize;

  int get _octaveDisplay => (2 + _octaveOffset).clamp(-2, 8);

  @override
  void initState() {
    super.initState();
    _surfaceMode = widget.initialSurfaceMode ?? PlaySurfaceMode.keys;
    _octaveOffset = widget.initialOctaveOffset;
  }

  @override
  void didUpdateWidget(covariant PlayDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSurfaceMode != null &&
        widget.initialSurfaceMode != oldWidget.initialSurfaceMode) {
      _surfaceMode = widget.initialSurfaceMode!;
    }
  }

  void setSurfaceMode(PlaySurfaceMode mode) {
    if (_surfaceMode == mode) return;
    setState(() {
      _surfaceMode = mode;
      _view = PlayContextView.perform;
      _highlightedPitches.clear();
    });
  }

  void toggleLatch() {
    setState(() => _latch = !_latch);
    widget.onPerformanceChanged?.call();
  }

  void toggleMetronome() {
    setState(() => _metronome = !_metronome);
    widget.onPerformanceChanged?.call();
  }

  void setMetronome(bool value) {
    if (_metronome == value) return;
    setState(() => _metronome = value);
    widget.onPerformanceChanged?.call();
  }

  void _notifyPerformance() => widget.onPerformanceChanged?.call();

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

  Widget _buildContextArea(PlayScale scale) {
    if (!widget.enabled) {
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
              velocityCurve: _velocityCurve,
              quantize: _quantize,
              customScales: _customScales,
              onOctaveDelta: _onOctaveDelta,
              onRowCountChanged: (r) => setState(() => _keyboardRows = r),
              onScaleChanged: (id) => setState(() => _scaleId = id),
              onInKeyToggle: () => setState(() => _inKeyOnly = !_inKeyOnly),
              onVelocityCurveChanged: (c) => setState(() => _velocityCurve = c),
              onQuantizeChanged: (q) {
                setState(() => _quantize = q);
                _notifyPerformance();
              },
              onEditCustomScales: () =>
                  setState(() => _view = PlayContextView.scaleBuilder),
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
      case PlayContextView.performancePanel:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: PerformancePanel(
              latch: _latch,
              sustain: _sustain,
              repeat: _repeat,
              metronome: _metronome,
              chordMemory: _chordMemory,
              onLatchToggle: () {
                setState(() => _latch = !_latch);
                _notifyPerformance();
              },
              onSustainToggle: () => setState(() => _sustain = !_sustain),
              onRepeatToggle: () => setState(() => _repeat = !_repeat),
              onMetronomeToggle: () {
                setState(() => _metronome = !_metronome);
                _notifyPerformance();
              },
              onStoreChord: () {
                final slot = (_chordMemory.length % 8);
                final label = _chord.label;
                setState(() {
                  if (slot < _chordMemory.length) {
                    _chordMemory[slot] = ChordMemory(label: label, quality: _chord);
                  } else {
                    _chordMemory.add(ChordMemory(label: label, quality: _chord));
                  }
                });
              },
              onRecallChord: (i) {
                if (i < _chordMemory.length) {
                  setState(() {
                    _chord = _chordMemory[i].quality;
                    _updateHighlights(_activeRootOffset);
                  });
                }
              },
            ),
          ),
        );
      case PlayContextView.scaleBuilder:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ScaleBuilderPanel(
              onSave: (scale) {
                setState(() {
                  _customScales.add(scale);
                  _scaleId = scale.id;
                  _view = PlayContextView.octave;
                });
              },
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
                    pitchBase: widget.padPitchBase,
                    highlightedPitches: _highlightedPitches,
                    chokeGroupByColumn: _padChokeByColumn,
                    chokeGroupByRow: _padChokeByRow,
                    noteRepeatMs: _repeat ? _rateMs : 0,
                    velocityCurve: _velocityCurve,
                    onModulationChanged: (v) => setState(() => _modulation = v),
                    onPitchBendChanged: (v) => setState(() => _pitchBend = v),
                  )
                : PlayKeyboard(
                    bridge: widget.bridge,
                    scale: scale,
                    inKeyOnly: _inKeyOnly && scale.id != 'chromatic',
                    octaveOffset: _octaveOffset,
                    rowCount: _keyboardRows,
                    highlightedPitches: _highlightedPitches,
                    velocityCurve: _velocityCurve,
                    onModulationChanged: (v) => setState(() => _modulation = v),
                    onPitchBendChanged: (v) => setState(() => _pitchBend = v),
                  ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = PlayScale.byId(_scaleId, custom: _customScales);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showModStrip)
          ModStrip(modulation: _modulation, pitchBend: _pitchBend),
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
                  enabled: widget.enabled,
                  onSurfaceModeChanged: _onSurfaceModeChanged,
                  onViewChanged: _onViewChanged,
                ),
                Expanded(child: _buildContextArea(scale)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
