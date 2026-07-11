part of 'time_fx_panels.dart';

class _MorphModeGroupState extends State<_MorphModeGroup>
    with SingleTickerProviderStateMixin {
  bool _assigning = false;
  bool _highlightsVisible = true;
  double _startY = 0;
  double _assignment = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool get _pulseActive => widget.connectModeActive || widget.linkModeActive;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: .15, end: .45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MorphModeGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.connectModeActive || oldWidget.linkModeActive;
    if (_pulseActive && !wasActive) {
      _pulseController.repeat(reverse: true);
    } else if (!_pulseActive && wasActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _longPress() {
    HapticFeedback.mediumImpact();
    if (widget.linkModeActive) {
      widget.onAutomationLinkTap?.call();
    } else if (!widget.connectModeActive) {
      widget.onAutomateRequest?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value.round().clamp(0, 3);
    final shownAmount = _assigning ? _assignment : widget.modulationAmount;
    final pulseAccent =
        widget.linkModeActive ? const Color(0xFFB48CFF) : widget.accent;
    final showPulse = _pulseActive && _highlightsVisible;
    final showModulationAmount = _assigning
        ? shownAmount.abs() > 0
        : widget.modulationActive && shownAmount.abs() > 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.linkModeActive ? widget.onAutomationLinkTap : null,
      onLongPress: widget.connectModeActive ? null : _longPress,
      onLongPressStart: widget.connectModeActive
          ? (details) {
              HapticFeedback.mediumImpact();
              _pulseController.stop();
              _startY = details.localPosition.dy;
              setState(() {
                _highlightsVisible = false;
                _assigning = true;
                _assignment = 0;
              });
            }
          : null,
      onLongPressMoveUpdate: widget.connectModeActive
          ? (details) => setState(() {
                _assignment = ((_startY - details.localPosition.dy) / 100)
                    .clamp(-1.0, 1.0);
              })
          : null,
      onLongPressEnd: widget.connectModeActive
          ? (_) {
              widget.onModulationAssign?.call(_assignment);
              _pulseController.reset();
              if (_pulseActive) _pulseController.repeat(reverse: true);
              setState(() {
                _highlightsVisible = true;
                _assigning = false;
                _assignment = 0;
              });
            }
          : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Container(
          key: ValueKey('${widget.keyPrefix}-group'),
          height: 36,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              pulseAccent.withValues(
                alpha: showPulse ? _pulseAnimation.value : 0,
              ),
              const Color(0xFF121218),
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: showPulse
                  ? pulseAccent.withValues(alpha: .75)
                  : Colors.white.withValues(alpha: .08),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    for (var index = 0;
                        index < widget.labels.length;
                        index++) ...[
                      Expanded(
                        child: Material(
                          color: index == selected
                              ? widget.accent.withValues(alpha: .18)
                              : Colors.transparent,
                          child: InkWell(
                            key: ValueKey(
                              '${widget.keyPrefix}-${widget.labels[index]}',
                            ),
                            onTap: widget.linkModeActive
                                ? widget.onAutomationLinkTap
                                : () => widget.onChanged(index.toDouble()),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.labels[index],
                                  style: TextStyle(
                                    color: index == selected
                                        ? widget.accent
                                        : Colors.white38,
                                    fontSize: 8,
                                    fontWeight: index == selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (index < widget.labels.length - 1)
                        Container(
                          width: 1,
                          color: Colors.white.withValues(alpha: .06),
                        ),
                    ],
                  ],
                ),
              ),
              if (showModulationAmount)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: ValueKey('${widget.keyPrefix}-modulation-line'),
                      painter: _ChorusModulationLinePainter(
                        value: widget.value,
                        amount: shownAmount,
                        inAssignment: _assigning,
                      ),
                    ),
                  ),
                ),
              if (widget.automationActive)
                Positioned(
                  left: 3,
                  top: 3,
                  child: IgnorePointer(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB48CFF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: .5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
