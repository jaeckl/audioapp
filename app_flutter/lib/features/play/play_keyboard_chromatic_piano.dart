part of 'play_keyboard.dart';

class _ChromaticPiano extends StatelessWidget {
  const _ChromaticPiano({
    required this.octaveRoot,
    required this.rows,
    required this.held,
    required this.highlighted,
    required this.onDown,
    required this.onUp,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerEnd,
  });

  final int octaveRoot;
  final int rows;
  final Set<int> held;
  final Set<int> highlighted;
  final Future<void> Function(int pitch, double y, double h) onDown;
  final Future<void> Function(int pitch) onUp;
  final void Function(int pitch, int pointer, Offset local) onPointerDown;
  final void Function(int pointer, Offset local, Size keySize) onPointerMove;
  final Future<void> Function(int pointer) onPointerEnd;

  static const _whiteSteps = [0, 2, 4, 5, 7, 9, 11];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final landscape = PlayDeckLayout.isLandscape(size);
        final octaveCount = landscape
            ? PlayDeckLayout.octaveCountForWidth(constraints.maxWidth)
            : rows.clamp(1, PlayDeckLayout.maxKeyboardOctaves);

        // Landscape: octaves side-by-side (more keys by width).
        // Portrait: one octave per row, stacked (higher octave on top).
        if (landscape || octaveCount == 1) {
          return _octaveStrip(
            root: octaveRoot,
            octaveCount: octaveCount,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          );
        }

        final gap = PlayDeckTheme.cellGap;
        final rowH =
            (constraints.maxHeight - gap * (octaveCount - 1)) / octaveCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var o = octaveCount - 1; o >= 0; o--) ...[
              if (o < octaveCount - 1) SizedBox(height: gap),
              SizedBox(
                height: rowH,
                child: _octaveStrip(
                  root: octaveRoot + o * 12,
                  octaveCount: 1,
                  width: constraints.maxWidth,
                  height: rowH,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _octaveStrip({
    required int root,
    required int octaveCount,
    required double width,
    required double height,
  }) {
    final gap = PlayDeckTheme.cellGap;
    final whiteCount = _whiteSteps.length * octaveCount;
    final whiteW = (width - gap * (whiteCount - 1)) / whiteCount;
    final blackH = height * 0.58;
    final blackW = whiteW * 0.62;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            for (var i = 0; i < whiteCount; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                child: _KeyCell(
                  light: true,
                  isRoot: _whiteSteps[i % _whiteSteps.length] == 0,
                  active: _isActive(_pitchAt(root, i)),
                  onDown: (y, h) => onDown(_pitchAt(root, i), y, h),
                  onUp: () => onUp(_pitchAt(root, i)),
                  onPointerDown: (pointer, local) =>
                      onPointerDown(_pitchAt(root, i), pointer, local),
                  onPointerMove: onPointerMove,
                  onPointerEnd: onPointerEnd,
                ),
              ),
            ],
          ],
        ),
        for (var i = 0; i < whiteCount; i++)
          if (_hasBlackAfter(i % _whiteSteps.length))
            Positioned(
              left: _blackLeft(i, whiteW, gap, blackW),
              width: blackW,
              top: 0,
              height: blackH,
              child: _KeyCell(
                dark: true,
                isRoot: false,
                active: _isActive(_pitchAt(root, i) + 1),
                onDown: (y, h) => onDown(_pitchAt(root, i) + 1, y, h),
                onUp: () => onUp(_pitchAt(root, i) + 1),
                onPointerDown: (pointer, local) =>
                    onPointerDown(_pitchAt(root, i) + 1, pointer, local),
                onPointerMove: onPointerMove,
                onPointerEnd: onPointerEnd,
              ),
            ),
      ],
    );
  }

  int _pitchAt(int root, int whiteIndex) {
    final octave = whiteIndex ~/ _whiteSteps.length;
    final step = _whiteSteps[whiteIndex % _whiteSteps.length];
    return root + octave * 12 + step;
  }

  bool _isActive(int pitch) =>
      held.contains(pitch) || highlighted.contains(pitch);

  static bool _hasBlackAfter(int whiteStepIndex) {
    if (whiteStepIndex >= _whiteSteps.length - 1) return false;
    return _whiteSteps[whiteStepIndex + 1] - _whiteSteps[whiteStepIndex] == 2;
  }

  static double _blackLeft(
    int whiteIndex,
    double whiteW,
    double gap,
    double blackW,
  ) {
    final whiteRight = whiteIndex * (whiteW + gap) + whiteW;
    return whiteRight + gap / 2 - blackW / 2;
  }
}
