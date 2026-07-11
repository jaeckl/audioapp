part of 'device_tool_rail.dart';

class _ToolRailButtonState extends State<_ToolRailButton>
    with SingleTickerProviderStateMixin {
  double _dragStartY = 0;
  double _assignmentAmount = 0;
  bool _assignmentMode = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _pulseAnimation = Tween<double>(begin: 0.18, end: 0.42).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ToolRailButton oldWidget) {
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

  void _onTap() {
    if (widget.linkModeActive) {
      return;
    }
    widget.onPressed?.call();
  }

  void _onLongPress() {
    if (widget.linkModeActive && widget.onLinkTap != null) {
      HapticFeedback.mediumImpact();
      widget.onLinkTap!.call();
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
    _dragStartY = details.localPosition.dy;
    setState(() {
      _assignmentAmount = 0;
      _assignmentMode = true;
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_assignmentMode) return;
    final amount = details.localPosition.dy <= _dragStartY ? 1.0 : -1.0;
    setState(() => _assignmentAmount = amount);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_assignmentMode) return;
    widget.onModulationAssign?.call(_assignmentAmount);
    setState(() {
      _assignmentAmount = 0;
      _assignmentMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = !widget.enabled
        ? Colors.white24
        : widget.active
            ? Colors.white70
            : const Color(0xFFE86A6A);
    final highlight = widget.linkModeActive
        ? const Color(0xFFB48CFF)
        : const Color(0xFFE8A54B);
    final showModulationDot = widget.modulationActive ||
        (widget.linkModeActive && widget.automationActive);
    final modulationDotColor = widget.linkModeActive && widget.automationActive
        ? const Color(0xFFB48CFF)
        : const Color(0xFFE8A54B);

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _onTap : null,
        onLongPress: widget.enabled &&
                (widget.linkModeActive || !widget.connectModeActive)
            ? _onLongPress
            : null,
        onLongPressStart: widget.enabled && widget.connectModeActive
            ? _onLongPressStart
            : null,
        onLongPressMoveUpdate: widget.enabled && widget.connectModeActive
            ? _onLongPressMoveUpdate
            : null,
        onLongPressEnd:
            widget.enabled && widget.connectModeActive ? _onLongPressEnd : null,
        child: SizedBox(
          width: 28,
          height: 24,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (_pulseActive)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: highlight.withValues(
                          alpha: _pulseAnimation.value,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Icon(widget.icon, size: 18, color: color),
                  if (showModulationDot)
                    Positioned(
                      left: 5,
                      bottom: 3,
                      child: _StatusDot(
                        key: const ValueKey('tool_rail_modulation_dot'),
                        color: modulationDotColor,
                      ),
                    ),
                  if (widget.automationActive)
                    Positioned(
                      right: 5,
                      top: 3,
                      child: _StatusDot(
                        key: const ValueKey('tool_rail_automation_dot'),
                        color: const Color(0xFFB48CFF),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
