import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'play_deck_theme.dart';
import 'play_scale.dart';

/// Borderless 4×5 pad grid — Ableton Note style.
class MpcPadGrid extends StatefulWidget {
  const MpcPadGrid({
    super.key,
    required this.bridge,
    required this.bankOffset,
    this.highlightedPitches = const <int>{},
  });

  final EngineBridge bridge;
  final int bankOffset;
  final Set<int> highlightedPitches;

  static const columns = 4;
  static const rows = 5;
  static const padCount = columns * rows;

  @override
  State<MpcPadGrid> createState() => _MpcPadGridState();
}

class _MpcPadGridState extends State<MpcPadGrid> {
  final Set<int> _held = {};
  final Map<int, Timer> _flashTimers = {};

  int _pitchForPad(int index) => 48 + widget.bankOffset + index;

  Future<void> _down(int index, double localY, double height) async {
    setState(() => _held.add(index));
    _flashTimers[index]?.cancel();
    try {
      await widget.bridge.noteOn(
        pitch: _pitchForPad(index),
        velocity: velocityFromY(localY, height).toDouble(),
      );
    } catch (_) {}
  }

  Future<void> _up(int index) async {
    final pitch = _pitchForPad(index);
    setState(() => _held.remove(index));
    _flashTimers[index] = Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() {});
    });
    try {
      await widget.bridge.noteOff(pitch: pitch);
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final timer in _flashTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = PlayDeckTheme.cellGap;
        final cellH = (constraints.maxHeight - gap * (MpcPadGrid.rows - 1)) / MpcPadGrid.rows;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < MpcPadGrid.rows; row++) ...[
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
  });

  final bool active;
  final void Function(double localY, double height) onDown;
  final VoidCallback onUp;

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
      onPointerDown: (e) => widget.onDown(e.localPosition.dy, context.size?.height ?? 48),
      onPointerUp: (_) => widget.onUp(),
      onPointerCancel: (_) => widget.onUp(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 45),
        color: lit ? PlayDeckTheme.padActive : PlayDeckTheme.padIdle,
      ),
    );
  }
}
