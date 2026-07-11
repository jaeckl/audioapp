part of 'mood_fx_panels.dart';

class _StutterHoldButtonState extends State<_StutterHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _assignmentMode = false;
  double _dragStartY = 0.0;
  double _assignmentAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.14, end: 0.42).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StutterHoldButton oldWidget) {
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

  bool get _pulseActive => widget.connectModeActive || widget.linkModeActive;

  void _handleTap() {
    if (widget.linkModeActive) {
      return;
    }
    widget.onTap();
  }

  void _handleLongPress() {
    if (widget.linkModeActive) {
      HapticFeedback.mediumImpact();
      widget.onAutomationLinkTap?.call();
    } else if (!widget.connectModeActive) {
      HapticFeedback.mediumImpact();
      widget.onAutomateRequest?.call();
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!widget.connectModeActive) return;
    HapticFeedback.mediumImpact();
    _pulseController.stop();
    _dragStartY = details.localPosition.dy;
    setState(() {
      _assignmentMode = true;
      _assignmentAmount = 0.0;
    });
  }

  void _handleLongPressMove(LongPressMoveUpdateDetails details) {
    if (!_assignmentMode) return;
    final amount = details.localPosition.dy <= _dragStartY ? 1.0 : -1.0;
    setState(() => _assignmentAmount = amount);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_assignmentMode) return;
    widget.onModulationAssign?.call(_assignmentAmount);
    _pulseController.reset();
    if (_pulseActive) {
      _pulseController.repeat(reverse: true);
    }
    setState(() {
      _assignmentMode = false;
      _assignmentAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onLongPress: widget.linkModeActive || !widget.connectModeActive
              ? _handleLongPress
              : null,
          onLongPressStart:
              widget.connectModeActive ? _handleLongPressStart : null,
          onLongPressMoveUpdate:
              widget.connectModeActive ? _handleLongPressMove : null,
          onLongPressEnd: widget.connectModeActive ? _handleLongPressEnd : null,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final pulseAlpha = _pulseActive ? _pulseAnimation.value : 0.0;
              final fill = widget.active
                  ? widget.accent.withValues(alpha: 0.18)
                  : const Color(0xFF12121A);
              final stroke = widget.active
                  ? widget.accent.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.11);
              return SizedBox(
                width: DeviceStripMetrics.dynamicsFxKnobColumnWidth,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      widget.accent.withValues(alpha: pulseAlpha),
                      fill,
                    ),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: stroke, width: 1.2),
                    boxShadow: widget.active
                        ? [
                            BoxShadow(
                              color: widget.accent.withValues(alpha: 0.14),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: widget.active
                                        ? widget.accent
                                        : Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'HOLD',
                                    maxLines: 1,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: widget.active
                                          ? widget.accent
                                          : Colors.white54,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: widget.active
                                    ? widget.accent
                                    : Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.modulationActive || _assignmentMode)
                        Positioned(
                          left: 7,
                          right: 7,
                          bottom: 6,
                          child: _StutterModLine(
                            amount: _assignmentMode
                                ? _assignmentAmount
                                : widget.modulationAmount,
                            color: widget.accent,
                          ),
                        ),
                      if (widget.automationActive)
                        Positioned(
                          right: 5,
                          top: 5,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB48CFF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB48CFF)
                                      .withValues(alpha: 0.65),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Hold',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
