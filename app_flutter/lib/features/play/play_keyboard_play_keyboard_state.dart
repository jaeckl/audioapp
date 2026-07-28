part of 'play_keyboard.dart';

class _PlayKeyboardState extends State<PlayKeyboard> {
  final Set<int> _heldPitches = {};
  static const _rootMidi = 60;

  // Active drag tracking for mod/bend. Keyed by pointer so multi-finger
  // glides don't fight each other.
  final Map<int, _KeyDrag> _drags = {};
  double _currentMod = 0.0;
  double _currentBend = 0.0;
  static const double _modRangePx = 60.0; // px of horizontal drag for full mod
  static const double _bendRangePx = 50.0; // px of vertical drag for full bend

  List<int> get _allPitches {
    final scale = widget.inKeyOnly ? widget.scale : PlayScale.chromatic;
    return PlayScale.pitches(
      scale: scale,
      rootMidi: _rootMidi,
      octaveOffset: widget.octaveOffset,
      octaveCount: widget.rowCount.clamp(1, 3),
    );
  }

  Future<void> _noteDown(int pitch, double localY, double height) async {
    if (_heldPitches.contains(pitch)) return;
    setState(() => _heldPitches.add(pitch));
    try {
      await widget.bridge.noteOn(
        pitch: pitch,
        velocity: velocityFromY(localY, height, curve: widget.velocityCurve)
            .toDouble(),
      );
    } catch (_) {}
  }

  Future<void> _noteUp(int pitch) async {
    if (!_heldPitches.remove(pitch)) return;
    setState(() {});
    try {
      await widget.bridge.noteOff(pitch: pitch);
    } catch (_) {}
  }

  void _onKeyPointerDown(int pitch, int pointer, Offset local) {
    _drags[pointer] = _KeyDrag(pitch: pitch, origin: local, last: local);
  }

  void _onKeyPointerMove(int pointer, Offset local, Size keySize) {
    final drag = _drags[pointer];
    if (drag == null) return;
    final dx = local.dx - drag.origin.dx;
    final dy = local.dy - drag.origin.dy;
    // Mod from horizontal drag.
    final mod = (dx / _modRangePx).clamp(0.0, 1.0);
    // Bend from vertical drag (positive = up = bend up).
    final bend = (-dy / _bendRangePx).clamp(-1.0, 1.0);
    if (mod != _currentMod) {
      _currentMod = mod;
      widget.onModulationChanged?.call(mod);
      try {
        widget.bridge.setModulation(mod);
      } catch (_) {}
    }
    if (bend != _currentBend) {
      _currentBend = bend;
      widget.onPitchBendChanged?.call(bend);
      try {
        widget.bridge.setPitchBend(bend);
      } catch (_) {}
    }
    drag.last = local;
  }

  Future<void> _onKeyPointerEnd(int pointer) async {
    _drags.remove(pointer);
    if (_drags.isNotEmpty) return; // another finger still down — keep current
    if (_currentMod != 0.0) {
      _currentMod = 0.0;
      widget.onModulationChanged?.call(0.0);
      try {
        await widget.bridge.setModulation(0.0);
      } catch (_) {}
    }
    if (_currentBend != 0.0) {
      _currentBend = 0.0;
      widget.onPitchBendChanged?.call(0.0);
      try {
        await widget.bridge.setPitchBend(0.0);
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.rowCount.clamp(1, 3);

    // Keys mode = real piano (white + black). In-key keeps equal note bars.
    if (!widget.inKeyOnly) {
      return _ChromaticPiano(
        octaveRoot: _rootMidi + widget.octaveOffset * 12,
        rows: rows,
        held: _heldPitches,
        highlighted: widget.highlightedPitches,
        onDown: _noteDown,
        onUp: _noteUp,
        onPointerDown: _onKeyPointerDown,
        onPointerMove: _onKeyPointerMove,
        onPointerEnd: _onKeyPointerEnd,
      );
    }

    return _ScaleKeyGrid(
      pitches: _allPitches,
      scale: widget.scale,
      rows: rows,
      scrollOffset: widget.scrollOffset,
      held: _heldPitches,
      highlighted: widget.highlightedPitches,
      onDown: _noteDown,
      onUp: _noteUp,
      onPointerDown: _onKeyPointerDown,
      onPointerMove: _onKeyPointerMove,
      onPointerEnd: _onKeyPointerEnd,
    );
  }
}
