part of 'mood_fx_panels.dart';

class _HorizontalGroupShellState extends State<_HorizontalGroupShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  bool _assigning = false;
  double _startY = 0, _amount = 0;

  bool get _linking => widget.connectModeActive || widget.linkModeActive;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pulse = Tween<double>(begin: .1, end: .35).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    if (_linking) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _HorizontalGroupShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasLinking = oldWidget.connectModeActive || oldWidget.linkModeActive;
    if (_linking && !wasLinking) {
      _pulseController.repeat(reverse: true);
    } else if (!_linking && wasLinking) {
      _pulseController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shownAmount = _assigning ? _amount : widget.modulationAmount;
    final showLine = widget.connectModeActive &&
        (_assigning || widget.modulationActive) &&
        shownAmount.abs() > 0;
    final lineStart =
        (widget.value / widget.maxValue).clamp(0.0, 1.0) * widget.width;
    final lineEnd =
        (lineStart + shownAmount * widget.width).clamp(0.0, widget.width);
    final pulseColor =
        widget.linkModeActive ? const Color(0xFFB48CFF) : widget.accent;
    const linePadding = 4.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.linkModeActive ? widget.onLinkTap : null,
      onLongPress: !_linking ? widget.onAutomateRequest : null,
      onLongPressStart: widget.connectModeActive
          ? (details) {
              HapticFeedback.mediumImpact();
              _pulseController.stop();
              setState(() {
                _assigning = true;
                _startY = details.localPosition.dy;
                _amount = 0;
              });
            }
          : null,
      onLongPressMoveUpdate: widget.connectModeActive
          ? (details) => setState(() => _amount =
              ((_startY - details.localPosition.dy) / 100).clamp(-1.0, 1.0))
          : null,
      onLongPressEnd: widget.connectModeActive
          ? (_) {
              widget.onModulationAssign?.call(_amount);
              setState(() {
                _assigning = false;
                _amount = 0;
              });
              if (_linking) _pulseController.repeat(reverse: true);
            }
          : null,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(clipBehavior: Clip.hardEdge, children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _linking
                      ? pulseColor.withValues(alpha: _pulse.value)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: _linking
                          ? pulseColor.withValues(alpha: .7)
                          : Colors.white.withValues(alpha: .08)),
                ),
                child: child,
              ),
            ),
            if (showLine)
              Positioned(
                left: math.min(lineStart, lineEnd) + linePadding,
                bottom: 2,
                width:
                    math.max(0, (lineEnd - lineStart).abs() - linePadding * 2),
                child: Container(
                  height: 3 * 0.75,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            if (widget.automationActive)
              const Positioned(
                left: 3,
                top: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Color(0xFFB48CFF), shape: BoxShape.circle),
                  child: SizedBox(width: 6, height: 6),
                ),
              ),
          ]),
        ),
        child: widget.child,
      ),
    );
  }
}
