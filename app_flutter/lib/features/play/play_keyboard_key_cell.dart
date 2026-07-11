part of 'play_keyboard.dart';

class _KeyCell extends StatelessWidget {
  const _KeyCell({
    required this.isRoot,
    required this.active,
    required this.onDown,
    required this.onUp,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerEnd,
    this.light = false,
    this.dark = false,
  });

  final bool isRoot;
  final bool active;
  final bool light;
  final bool dark;

  final void Function(double y, double h) onDown;
  final VoidCallback onUp;
  final void Function(int pointer, Offset local) onPointerDown;
  final void Function(int pointer, Offset local, Size keySize) onPointerMove;
  final Future<void> Function(int pointer) onPointerEnd;

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
      onPointerDown: (e) {
        onDown(e.localPosition.dy, context.size?.height ?? 48);
        onPointerDown(e.pointer, e.localPosition);
      },
      onPointerMove: (e) {
        onPointerMove(
            e.pointer, e.localPosition, context.size ?? const Size(60, 60));
      },
      onPointerUp: (e) {
        onUp();
        onPointerEnd(e.pointer);
      },
      onPointerCancel: (e) {
        onUp();
        onPointerEnd(e.pointer);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 45),
        color: color,
      ),
    );
  }
}
