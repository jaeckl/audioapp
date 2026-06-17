import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'play_deck_theme.dart';
import 'play_scale.dart';

class MpcPadGrid extends StatefulWidget {
  const MpcPadGrid({
    super.key,
    required this.bridge,
    required this.bankOffset,
    this.highlightedPitches = const <int>{},
    this.chokeGroupByColumn = false,
    this.chokeGroupByRow = false,
    this.noteRepeatMs = 0,
    this.velocityCurve = VelocityCurve.linear,
    this.onModulationChanged,
    this.onPitchBendChanged,
    this.rowCount = 5,
  });

  final EngineBridge bridge;
  final int bankOffset;
  final Set<int> highlightedPitches;
  final bool chokeGroupByColumn;
  final bool chokeGroupByRow;
  final int noteRepeatMs;
  final VelocityCurve velocityCurve;
  final ValueChanged<double>? onModulationChanged;
  final ValueChanged<double>? onPitchBendChanged;
  final int rowCount;

  static const columns = 4;
  static const rows = 5;
  static const padCount = columns * rows;

  @override
  State<MpcPadGrid> createState() => _MpcPadGridState();
}

class _MpcPadGridState extends State<MpcPadGrid> {
  final Set<int> _held = {};
  final Map<int, Timer> _flashTimers = {};
  final Map<int, Timer> _repeatTimers = {};
  final Map<int, int> _lastChokedPitch = {};

  // Drag tracking for mod / bend. Horizontal on a held pad = mod;
  // vertical = bend. Resets on release.
  final Map<int, _PadDrag> _drags = {};
  double _currentMod = 0.0;
  double _currentBend = 0.0;
  static const double _modRangePx = 60.0;
  static const double _bendRangePx = 50.0;

  int _pitchForPad(int index) => 48 + widget.bankOffset + index;

  int get _rows => widget.rowCount;
  int get _padCount => MpcPadGrid.columns * _rows;

  void _chokeSiblings(int index) {
    if (!widget.chokeGroupByColumn && !widget.chokeGroupByRow) return;
    final col = index % MpcPadGrid.columns;
    final row = index ~/ MpcPadGrid.columns;
    for (var i = 0; i < _padCount; i++) {
      if (i == index) continue;
      final sameCol = widget.chokeGroupByColumn && i % MpcPadGrid.columns == col;
      final sameRow = widget.chokeGroupByRow && i ~/ MpcPadGrid.columns == row;
      if (sameCol || sameRow) {
        _releasePad(i, sendNoteOff: true);
      }
    }
  }

  Future<void> _down(int index, double localY, double height) async {
    setState(() => _held.add(index));
    _flashTimers[index]?.cancel();
    _chokeSiblings(index);
    final pitch = _pitchForPad(index);
    _lastChokedPitch[index] = pitch;
    final velocity = velocityFromY(localY, height, curve: widget.velocityCurve).toDouble();
    try {
      await widget.bridge.noteOn(pitch: pitch, velocity: velocity);
    } catch (_) {}
    if (widget.noteRepeatMs > 0) {
      _repeatTimers[index]?.cancel();
      _repeatTimers[index] = Timer.periodic(
        Duration(milliseconds: widget.noteRepeatMs),
        (_) async {
          try {
            await widget.bridge.noteOff(pitch: pitch);
            await widget.bridge.noteOn(pitch: pitch, velocity: velocity);
          } catch (_) {}
        },
      );
    }
  }

  Future<void> _releasePad(int index, {bool sendNoteOff = true}) async {
    _held.remove(index);
    _repeatTimers.remove(index)?.cancel();
    if (sendNoteOff) {
      try {
        await widget.bridge.noteOff(pitch: _pitchForPad(index));
      } catch (_) {}
    }
  }

  Future<void> _up(int index) async {
    final pitch = _pitchForPad(index);
    setState(() => _held.remove(index));
    _repeatTimers.remove(index)?.cancel();
    _flashTimers[index] = Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() {});
    });
    try {
      await widget.bridge.noteOff(pitch: pitch);
    } catch (_) {}
  }

  void _onPadPointerDown(int index, int pointer, Offset local) {
    _drags[pointer] = _PadDrag(index: index, origin: local, last: local);
  }

  void _onPadPointerMove(int pointer, Offset local, Size padSize) {
    final drag = _drags[pointer];
    if (drag == null) return;
    final dx = local.dx - drag.origin.dx;
    final dy = local.dy - drag.origin.dy;
    final mod = (dx / _modRangePx).clamp(0.0, 1.0);
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

  Future<void> _onPadPointerEnd(int pointer) async {
    _drags.remove(pointer);
    if (_drags.isNotEmpty) return;
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
  void dispose() {
    for (final timer in _flashTimers.values) {
      timer.cancel();
    }
    for (final timer in _repeatTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = PlayDeckTheme.cellGap;
        final cellH = (constraints.maxHeight - gap * (_rows - 1)) / _rows;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < _rows; row++) ...[
              if (row > 0) SizedBox(height: gap),
              SizedBox(
                height: cellH,
                child: Row(
                  children: [
                    for (var col = 0; col < MpcPadGrid.columns; col++) ...[
                      if (col > 0) SizedBox(width: gap),
                      Expanded(
                        child: _PadCell(
                          active: _held.contains(row * MpcPadGrid.columns + col) ||
                              widget.highlightedPitches
                                  .contains(_pitchForPad(row * MpcPadGrid.columns + col)),
                          onDown: (y, h) => _down(row * MpcPadGrid.columns + col, y, h),
                          onUp: () => _up(row * MpcPadGrid.columns + col),
                          onPointerDown: (pointer, local) =>
                              _onPadPointerDown(row * MpcPadGrid.columns + col, pointer, local),
                          onPointerMove: _onPadPointerMove,
                          onPointerEnd: _onPadPointerEnd,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PadCell extends StatefulWidget {
  const _PadCell({
    required this.active,
    required this.onDown,
    required this.onUp,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerEnd,
  });

  final bool active;
  final void Function(double localY, double height) onDown;
  final VoidCallback onUp;
  final void Function(int pointer, Offset local) onPointerDown;
  final void Function(int pointer, Offset local, Size padSize) onPointerMove;
  final Future<void> Function(int pointer) onPointerEnd;

  @override
  State<_PadCell> createState() => _PadCellState();
}

class _PadCellState extends State<_PadCell> {
  bool _flash = false;
  Timer? _flashOffTimer;

  @override
  void dispose() {
    _flashOffTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PadCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      setState(() => _flash = true);
    }
    if (!widget.active && oldWidget.active) {
      _flashOffTimer?.cancel();
      _flashOffTimer = Timer(const Duration(milliseconds: 70), () {
        if (mounted) setState(() => _flash = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lit = widget.active || _flash;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        widget.onDown(e.localPosition.dy, context.size?.height ?? 48);
        widget.onPointerDown(e.pointer, e.localPosition);
      },
      onPointerMove: (e) {
        widget.onPointerMove(e.pointer, e.localPosition, context.size ?? const Size(80, 80));
      },
      onPointerUp: (e) {
        widget.onUp();
        widget.onPointerEnd(e.pointer);
      },
      onPointerCancel: (e) {
        widget.onUp();
        widget.onPointerEnd(e.pointer);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 45),
        color: lit ? PlayDeckTheme.padActive : PlayDeckTheme.padIdle,
      ),
    );
  }
}

class _PadDrag {
  _PadDrag({required this.index, required this.origin, required this.last});
  final int index;
  final Offset origin;
  Offset last;
}
