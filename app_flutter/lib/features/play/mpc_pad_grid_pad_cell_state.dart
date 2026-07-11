part of 'mpc_pad_grid.dart';

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
        widget.onPointerMove(
            e.pointer, e.localPosition, context.size ?? const Size(80, 80));
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
