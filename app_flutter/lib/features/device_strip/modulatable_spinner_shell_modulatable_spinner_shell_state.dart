part of 'modulatable_spinner_shell.dart';

class _ModulatableSpinnerShellState extends State<ModulatableSpinnerShell>
    with SingleTickerProviderStateMixin {
  bool _assignmentMode = false;
  double _assignmentAmount = 0.0;
  double _dragStartY = 0;
  bool _highlightsVisible = true;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.connectModeActive || widget.linkModeActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ModulatableSpinnerShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pulseActive = widget.connectModeActive || widget.linkModeActive;
    final oldPulseActive =
        oldWidget.connectModeActive || oldWidget.linkModeActive;
    if (pulseActive && !oldPulseActive) {
      _pulseController.repeat(reverse: true);
    } else if (!pulseActive && oldPulseActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onLongPress() {
    if (widget.linkModeActive) {
      if (widget.onLinkTap != null) {
        HapticFeedback.mediumImpact();
        widget.onLinkTap!.call();
      }
      return;
    }
    if (!widget.connectModeActive && widget.onAutomateRequest != null) {
      HapticFeedback.mediumImpact();
      widget.onAutomateRequest!.call();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.connectModeActive) return;
    HapticFeedback.mediumImpact();
    _pulseController.stop();
    _assignmentAmount = 0.0;
    _dragStartY = details.localPosition.dy;
    setState(() {
      _highlightsVisible = false;
      _assignmentMode = true;
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_assignmentMode) return;
    const sensitivity = 200.0;
    final dy = details.localPosition.dy - _dragStartY;
    final amount = (-dy / sensitivity).clamp(-1.0, 1.0);
    setState(() => _assignmentAmount = amount);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_assignmentMode) return;
    widget.onModulationAssign?.call(_assignmentAmount);
    _pulseController.reset();
    if (widget.connectModeActive || widget.linkModeActive) {
      _pulseController.repeat(reverse: true);
    }
    setState(() {
      _highlightsVisible = true;
      _assignmentMode = false;
      _assignmentAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pulseAccent = widget.linkModeActive
        ? LibraryTheme.accentAutomation
        : widget.accentColor;
    final showConnectPulse =
        (widget.connectModeActive || widget.linkModeActive) &&
            _highlightsVisible;

    final showBar = _assignmentMode
        ? _assignmentAmount.abs() > 0
        : widget.modulationActive && widget.modulationAmount.abs() > 0;
    final barAmount =
        _assignmentMode ? _assignmentAmount : widget.modulationAmount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.linkModeActive && widget.onLinkTap != null
          ? () {
              HapticFeedback.mediumImpact();
              widget.onLinkTap!.call();
            }
          : null,
      onLongPress: widget.linkModeActive || !widget.connectModeActive
          ? _onLongPress
          : null,
      onLongPressStart: widget.connectModeActive ? _onLongPressStart : null,
      onLongPressMoveUpdate:
          widget.connectModeActive ? _onLongPressMoveUpdate : null,
      onLongPressEnd: widget.connectModeActive ? _onLongPressEnd : null,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: pulseAccent.withValues(alpha: widget.borderAlpha),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (showConnectPulse)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: CustomPaint(
                          painter: _SpinnerBackgroundGlowPainter(
                            glowColor: pulseAccent.withValues(
                                alpha: _pulseAnimation.value),
                            borderRadius: 3,
                          ),
                        ),
                      ),
                    ),
                  widget.child,
                  if (showBar)
                    ModulationVerticalBar(
                      polarity: widget.modulatorPolarity,
                      amount: barAmount,
                      currentAmount:
                          !widget.connectModeActive && !widget.linkModeActive
                              ? widget.liveModulationAmount
                              : null,
                      inAssignment: _assignmentMode,
                    ),
                  if (widget.automationActive)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: IgnorePointer(
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: LibraryTheme.accentAutomation,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.black.withValues(alpha: 0.5),
                                width: 1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
