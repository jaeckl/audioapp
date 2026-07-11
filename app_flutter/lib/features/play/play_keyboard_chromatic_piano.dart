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
        onPointerDown: onPointerDown,
        onPointerMove: onPointerMove,
        onPointerEnd: onPointerEnd,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = PlayDeckTheme.cellGap;
        const whiteCount = 7;
        final blackH = constraints.maxHeight * 0.34;
        final whiteH = constraints.maxHeight - blackH - gap;
        final whiteW =
            (constraints.maxWidth - gap * (whiteCount - 1)) / whiteCount;

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
                          active: held
                                  .contains(octaveRoot + _whiteSteps[i] + 1) ||
                              highlighted
                                  .contains(octaveRoot + _whiteSteps[i] + 1),
                          onDown: (y, h) =>
                              onDown(octaveRoot + _whiteSteps[i] + 1, y, h),
                          onUp: () => onUp(octaveRoot + _whiteSteps[i] + 1),
                          onPointerDown: (pointer, local) => onPointerDown(
                              octaveRoot + _whiteSteps[i] + 1, pointer, local),
                          onPointerMove: onPointerMove,
                          onPointerEnd: onPointerEnd,
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
                        onDown: (y, h) =>
                            onDown(octaveRoot + _whiteSteps[i], y, h),
                        onUp: () => onUp(octaveRoot + _whiteSteps[i]),
                        onPointerDown: (pointer, local) => onPointerDown(
                            octaveRoot + _whiteSteps[i], pointer, local),
                        onPointerMove: onPointerMove,
                        onPointerEnd: onPointerEnd,
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
                  pitches:
                      List.generate(7, (i) => octaveRoot + 12 + _whiteSteps[i]),
                  scale: PlayScale.chromatic,
                  rows: 1,
                  scrollOffset: 0,
                  held: held,
                  highlighted: highlighted,
                  onDown: onDown,
                  onUp: onUp,
                  onPointerDown: onPointerDown,
                  onPointerMove: onPointerMove,
                  onPointerEnd: onPointerEnd,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
