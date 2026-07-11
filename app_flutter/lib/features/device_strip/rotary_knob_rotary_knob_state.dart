part of 'rotary_knob.dart';

class _RotaryKnobState extends State<RotaryKnob>
    with SingleTickerProviderStateMixin {
  double _dragStartValue = 0;
  double _dragStartY = 0;
  bool _highlightsVisible = true;

  // Modulation assignment gesture state (connect mode)
  bool _assignmentMode = false;
  double _assignmentAmount = 0.0;

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
  void didUpdateWidget(covariant RotaryKnob oldWidget) {
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

  // --- Normal knob drag (changes value) ---

  void _onDragStart(DragStartDetails details) {
    _dragStartValue = widget.value;
    _dragStartY = details.localPosition.dy;
    // In connect mode the long-press handles the modulation gesture;
    // plain drags still change the value normally.
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final sensitivity = 120.0 + widget.size * 2;
    final delta = (_dragStartY - details.localPosition.dy) / sensitivity;
    widget.onChanged((_dragStartValue + delta).clamp(0.0, 1.0));
  }

  void _onDragEnd(DragEndDetails details) {
    // Not involved in connect-mode gesture — long-press handles it.
  }

  void _onDragCancel() {}

  // --- Connect-mode long-press modulation assignment ---

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
    _dragStartY = details.localPosition.dy; // reuse for assignment drag origin
    setState(() {
      _highlightsVisible = false;
      _assignmentMode = true;
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_assignmentMode) return;
    // Sensitivity: 200 px vertical travel = 1.0 amount (full range)
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
    final stroke = widget.size >= DeviceKnobSizes.editor ? 4.0 : 3.0;
    final theme = Theme.of(context);
    final angle = KnobArcGeometry.indicatorAngle(widget.value);
    final labelSize = widget.size >= DeviceKnobSizes.strip ? 10.0 : 9.0;
    final pulseAccent =
        widget.linkModeActive ? widget.linkModeAccent : widget.accentColor;
    final showConnectPulse =
        (widget.connectModeActive || widget.linkModeActive) &&
            _highlightsVisible;
    final effectivePolarity =
        widget.polarityParamId != null && widget.deviceId != null
            ? modulatorPolarityForParam(
                paramId: widget.polarityParamId!,
                deviceId: widget.deviceId!,
                modEdges: widget.modEdges,
                lfos: widget.lfos,
                connectModeLfoId:
                    widget.connectModeActive ? widget.connectModeLfoId : null,
              )
            : widget.modulatorPolarity;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
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
          onVerticalDragStart: widget.linkModeActive ? null : _onDragStart,
          onVerticalDragUpdate: widget.linkModeActive ? null : _onDragUpdate,
          onVerticalDragEnd: widget.linkModeActive ? null : _onDragEnd,
          onVerticalDragCancel: widget.linkModeActive ? null : _onDragCancel,
          onDoubleTap: () => widget.onChanged(0.5),
          child: SizedBox(
            width: widget.size + 8,
            height: widget.size + 4,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final showGlow = showConnectPulse;
                return CustomPaint(
                  painter: showGlow
                      ? _BackgroundGlowPainter(
                          glowColor: pulseAccent.withValues(
                              alpha: _pulseAnimation.value),
                          borderRadius: 8,
                          center: KnobArcGeometry.visualCenterInCenteredHost(
                            knobSize: widget.size,
                            hostSize: Size(widget.size + 8, widget.size + 4),
                          ),
                        )
                      : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: _KnobPainter(
                            value: widget.value.clamp(0, 1),
                            angle: angle,
                            accentColor: pulseAccent,
                            strokeWidth: stroke,
                            modulationActive: widget.modulationActive,
                            modulationAmount: widget.modulationAmount,
                            modulatorPolarity: effectivePolarity,
                            connectModeActive: showConnectPulse,
                            assignmentMode: _assignmentMode,
                            assignmentAmount: _assignmentAmount,
                          ),
                        ),
                      ),
                      if (widget.automationActive)
                        Positioned(
                          top: 0,
                          right: 4,
                          child: IgnorePointer(
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB48CFF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF14141C),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB48CFF)
                                        .withValues(alpha: 0.7),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (widget.displayValue != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.displayValue!,
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: widget.accentColor,
                                fontSize: widget.size * 0.17,
                                fontWeight: FontWeight.w700,
                                height: 1,
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
        ),
        if (widget.showLabel) ...[
          SizedBox(height: widget.labelGap),
          if (widget.labelOptions.isEmpty)
            SizedBox(
              width: widget.size + 8,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              key: ValueKey('knob-label-menu-${widget.label}'),
              tooltip: 'Select ${widget.label} mode',
              initialValue: widget.label,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 96),
              color: const Color(0xFF22222E),
              onSelected: widget.onLabelOptionSelected,
              itemBuilder: (context) => widget.labelOptions
                  .map((option) => PopupMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
              child: SizedBox(
                width: widget.size + 8,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_left,
                          size: 10, color: Colors.white54),
                      Text(
                        widget.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontSize: labelSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 10, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
