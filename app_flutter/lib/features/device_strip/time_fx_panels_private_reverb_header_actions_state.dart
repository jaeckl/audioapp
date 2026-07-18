part of 'time_fx_panels.dart';

class _ReverbHeaderActionsState extends State<ReverbHeaderActions>
    with SingleTickerProviderStateMixin {
  static const _modes = ['ROOM', 'PLATE', 'HALL', 'SPACE'];
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  bool _assigning = false;
  double _startY = 0;
  double _amount = 0;

  bool get _pulseActive =>
      widget.connectModeLfoId != null || widget.automationLinkActive;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse = Tween<double>(begin: .1, end: .35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ReverbHeaderActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive =
        oldWidget.connectModeLfoId != null || oldWidget.automationLinkActive;
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

  @override
  Widget build(BuildContext context) {
    return EffectiveParameterValuesBuilder(
      fallbackValues: {
        'modeMorph': widget.device.modeMorph / 3,
        'freeze': widget.device.freeze,
      },
      activeParameterIds: widget.automatedParams,
      builder: (context, values) => _buildActions(
        (values['modeMorph']! * 3).round().clamp(0, 3),
        values['freeze']!,
      ),
    );
  }

  Widget _buildActions(int mode, double freeze) {
    const accent = ReverbFxPanel.accent;
    final shownAmount =
        _assigning ? _amount : widget.modulationAmounts['modeMorph'] ?? 0;
    final pulseColor =
        widget.automationLinkActive ? const Color(0xFFB48CFF) : accent;
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (details) {
              HapticFeedback.mediumImpact();
              if (widget.connectModeLfoId != null) {
                _pulseController.stop();
                setState(() {
                  _assigning = true;
                  _startY = details.localPosition.dy;
                  _amount = 0;
                });
              } else if (widget.automationLinkActive) {
                widget.onAutomationLinkTap?.call('modeMorph');
              } else {
                widget.onAutomateParameter?.call('modeMorph');
              }
            },
            onLongPressMoveUpdate: widget.connectModeLfoId == null
                ? null
                : (details) => setState(() {
                      _amount = ((_startY - details.localPosition.dy) / 70)
                          .clamp(-1.0, 1.0);
                    }),
            onLongPressEnd: widget.connectModeLfoId == null
                ? null
                : (_) {
                    widget.onModulationAssign?.call('modeMorph', _amount);
                    _pulseController.reset();
                    if (_pulseActive) {
                      _pulseController.repeat(reverse: true);
                    }
                    setState(() {
                      _assigning = false;
                      _amount = 0;
                    });
                  },
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => SizedBox(
                key: const ValueKey('reverb-header-mode'),
                width: 57,
                height: 40,
                child: Stack(
                  children: [
                    PopupMenuButton<int>(
                      key: const ValueKey('reverb-mode-menu'),
                      tooltip: 'Reverb algorithm',
                      padding: EdgeInsets.zero,
                      color: const Color(0xFF22222E),
                      onSelected: (index) => widget.onParameterChanged(
                        'modeMorph',
                        index.toDouble(),
                      ),
                      itemBuilder: (context) => [
                        for (var index = 0; index < _modes.length; index++)
                          PopupMenuItem<int>(
                            value: index,
                            height: 34,
                            child: Text(
                              _modes[index],
                              style: TextStyle(
                                color: index == mode ? accent : Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _modes[mode],
                              style: TextStyle(
                                color: _pulseActive
                                    ? Color.lerp(
                                        Colors.white60,
                                        pulseColor,
                                        _pulse.value,
                                      )
                                    : Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .25,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if ((widget.modulatedParams.contains('modeMorph') ||
                            _assigning) &&
                        shownAmount.abs() > 0)
                      Positioned(
                        left: shownAmount < 0 ? null : 5,
                        right: shownAmount < 0 ? 5 : null,
                        bottom: 7,
                        width: 44 * shownAmount.abs().clamp(0.05, 1.0),
                        child: ColoredBox(
                          color: pulseColor,
                          child: const SizedBox(height: 2),
                        ),
                      ),
                    if (widget.automatedParams.contains('modeMorph'))
                      const Positioned(
                        left: 2,
                        top: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFB48CFF),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 6, height: 6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('reverb-freeze'),
              customBorder: const CircleBorder(),
              onTap: () => widget.onParameterChanged(
                'freeze',
                freeze >= .5 ? 0 : 1,
              ),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                if (widget.automationLinkActive) {
                  widget.onAutomationLinkTap?.call('freeze');
                } else {
                  widget.onAutomateParameter?.call('freeze');
                }
              },
              child: SizedBox(
                width: 36,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.ac_unit,
                      size: 19,
                      color: freeze >= .5 ? accent : Colors.white54,
                    ),
                    if (widget.automatedParams.contains('freeze'))
                      const Positioned(
                        left: 3,
                        top: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFB48CFF),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 5, height: 5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
