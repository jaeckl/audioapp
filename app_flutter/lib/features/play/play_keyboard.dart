import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import 'play_deck_layout.dart';
import 'play_deck_theme.dart';
import 'play_scale.dart';

class PlayKeyboard extends StatefulWidget {
  const PlayKeyboard({
    super.key,
    required this.bridge,
    required this.scale,
    required this.inKeyOnly,
    required this.octaveOffset,
    required this.rowCount,
    this.scrollOffset = 0,
    this.highlightedPitches = const <int>{},
  });

  final EngineBridge bridge;
  final PlayScale scale;
  final bool inKeyOnly;
  final int octaveOffset;
  final int rowCount;
  final int scrollOffset;
  final Set<int> highlightedPitches;

  @override
  State<PlayKeyboard> createState() => _PlayKeyboardState();
}

class _PlayKeyboardState extends State<PlayKeyboard> {
  final Set<int> _heldPitches = {};
  static const _rootMidi = 60;

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
        velocity: velocityFromY(localY, height).toDouble(),
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

  @override
  Widget build(BuildContext context) {
    final rows = widget.rowCount.clamp(1, 3);
    final usePianoLayout = !widget.inKeyOnly && rows >= 2;

    if (usePianoLayout) {
      return _ChromaticPiano(
        octaveRoot: _rootMidi + widget.octaveOffset * 12,
        rows: rows,
        held: _heldPitches,
        highlighted: widget.highlightedPitches,
        onDown: _noteDown,
        onUp: _noteUp,
      );
    }

    return _ScaleKeyGrid(
      pitches: _allPitches,
      scale: widget.inKeyOnly ? widget.scale : PlayScale.chromatic,
      rows: rows,
      scrollOffset: widget.scrollOffset,
      held: _heldPitches,
      highlighted: widget.highlightedPitches,
      onDown: _noteDown,
      onUp: _noteUp,
    );
  }
}

class _ScaleKeyGrid extends StatelessWidget {
  const _ScaleKeyGrid({
    required this.pitches,
    required this.scale,
    required this.rows,
    required this.scrollOffset,
    required this.held,
    required this.highlighted,
    required this.onDown,
    required this.onUp,
  });

  final List<int> pitches;
  final PlayScale scale;
  final int rows;
  final int scrollOffset;
  final Set<int> held;
  final Set<int> highlighted;
  final Future<void> Function(int pitch, double y, double h) onDown;
  final Future<void> Function(int pitch) onUp;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = PlayDeckTheme.cellGap;
        final rowH = (constraints.maxHeight - gap * (rows - 1)) / rows;
        final cols = _columnCount(constraints.maxWidth, rowH, gap);
        final pageSize = cols * rows;
        final start = scrollOffset.clamp(0, (pitches.length - pageSize).clamp(0, pitches.length));
        final visible = pitches.sublist(
          start,
          (start + pageSize).clamp(0, pitches.length),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) SizedBox(height: gap),
              SizedBox(
                height: rowH,
                child: Row(
                  children: [
                    for (var c = 0; c < cols; c++) ...[
                      if (c > 0) SizedBox(width: gap),
                      Expanded(child: _cellAt(visible, start, r, c, cols)),
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

  Widget _cellAt(List<int> visible, int start, int row, int col, int cols) {
    final index = row * cols + col;
    if (index >= visible.length) {
      return const SizedBox.shrink();
    }
    final pitch = visible[index];
    final globalIndex = start + index;
    final isRoot = scale.id != 'chromatic' && globalIndex % scale.intervals.length == 0;

    return _KeyCell(
      light: scale.id == 'chromatic',
      isRoot: isRoot,
      active: held.contains(pitch) || highlighted.contains(pitch),
      onDown: (y, h) => onDown(pitch, y, h),
      onUp: () => onUp(pitch),
    );
  }

  int _columnCount(double width, double rowHeight, double gap) {
    final cellW = rowHeight.clamp(PlayDeckLayout.keyCellMinSize, 80.0);
    final cols = ((width + gap) / (cellW + gap)).floor();
    return cols.clamp(3, PlayDeckLayout.keyMaxColumns);
  }
}

class _ChromaticPiano extends StatelessWidget {
  const _ChromaticPiano({
    required this.octaveRoot,
    required this.rows,
    required this.held,
    required this.highlighted,
    required this.onDown,
    required this.onUp,
  });

  final int octaveRoot;
  final int rows;
  final Set<int> held;
  final Set<int> highlighted;
  final Future<void> Function(int pitch, double y, double h) onDown;
  final Future<void> Function(int pitch) onUp;

  static const _whiteSteps = [0, 2, 4, 5, 7, 9, 11];

  @override
  Widget build(BuildContext context) {
    if (rows == 1) {
      final whites = List.generate(7, (i) => octaveRoot + _whiteSteps[i]);
      return _ScaleKeyGrid(
        pitches: whites,
        scale: PlayScale.chromatic,
        rows: 1,
        scrollOffset: 0,
        held: held,
        highlighted: highlighted,
        onDown: onDown,
        onUp: onUp,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = PlayDeckTheme.cellGap;
        const whiteCount = 7;
        final blackH = constraints.maxHeight * 0.34;
        final whiteH = constraints.maxHeight - blackH - gap;
        final whiteW = (constraints.maxWidth - gap * (whiteCount - 1)) / whiteCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: blackH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < whiteCount - 1; i++)
                    if (_whiteSteps[i + 1] - _whiteSteps[i] == 2)
                      Positioned(
                        left: i * (whiteW + gap) + whiteW * 0.66,
                        width: whiteW * 0.68,
                        top: 0,
                        bottom: 0,
                        child: _KeyCell(
                          dark: true,
                          isRoot: false,
                          active: held.contains(octaveRoot + _whiteSteps[i] + 1) ||
                              highlighted.contains(octaveRoot + _whiteSteps[i] + 1),
                          onDown: (y, h) => onDown(octaveRoot + _whiteSteps[i] + 1, y, h),
                          onUp: () => onUp(octaveRoot + _whiteSteps[i] + 1),
                        ),
                      ),
                ],
              ),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: whiteH,
              child: Row(
                children: [
                  for (var i = 0; i < whiteCount; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    Expanded(
                      child: _KeyCell(
                        light: true,
                        isRoot: _whiteSteps[i] == 0,
                        active: held.contains(octaveRoot + _whiteSteps[i]) ||
                            highlighted.contains(octaveRoot + _whiteSteps[i]),
                        onDown: (y, h) => onDown(octaveRoot + _whiteSteps[i], y, h),
                        onUp: () => onUp(octaveRoot + _whiteSteps[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (rows == 3) ...[
              SizedBox(height: gap),
              Expanded(
                child: _ScaleKeyGrid(
                  pitches: List.generate(7, (i) => octaveRoot + 12 + _whiteSteps[i]),
                  scale: PlayScale.chromatic,
                  rows: 1,
                  scrollOffset: 0,
                  held: held,
                  highlighted: highlighted,
                  onDown: onDown,
                  onUp: onUp,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _KeyCell extends StatelessWidget {
  const _KeyCell({
    required this.isRoot,
    required this.active,
    required this.onDown,
    required this.onUp,
    this.light = false,
    this.dark = false,
  });

  final bool isRoot;
  final bool active;
  final bool light;
  final bool dark;

  final void Function(double y, double h) onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    final base = dark
        ? PlayDeckTheme.keyBlack
        : light
            ? PlayDeckTheme.keyWhite
            : PlayDeckTheme.keyIdle;
    final color = active
        ? PlayDeckTheme.keyActive
        : isRoot && !light
            ? PlayDeckTheme.keyRoot.withValues(alpha: 0.35)
            : base;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => onDown(e.localPosition.dy, context.size?.height ?? 48),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 45),
        color: color,
      ),
    );
  }
}
