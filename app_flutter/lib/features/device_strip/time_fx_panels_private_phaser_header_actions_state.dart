part of 'time_fx_panels.dart';

class _PhaserHeaderActionsState extends State<PhaserHeaderActions>
    with SingleTickerProviderStateMixin {
  static const waveforms = ['SINE', 'TRIANGLE', 'RAMP', 'RANDOM'];
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  bool _assigning = false;
  double _startY = 0;
  double _amount = 0;

  bool get _linkActive =>
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
    if (_linkActive) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PhaserHeaderActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive =
        oldWidget.connectModeLfoId != null || oldWidget.automationLinkActive;
    if (_linkActive && !wasActive) {
      _pulseController.repeat(reverse: true);
    } else if (!_linkActive && wasActive) {
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
    return EffectiveParameterValueBuilder(
      parameterId: 'waveform',
      fallbackValue: widget.device.phaserWaveform / 3,
      active: widget.automatedParams.contains('waveform'),
      builder: (context, value) =>
          _buildSelector((value * 3).round().clamp(0, 3)),
    );
  }

  Widget _buildSelector(int waveform) {
    const accent = PhaserFxPanel.accent;
    final shownAmount =
        _assigning ? _amount : widget.modulationAmounts['waveform'] ?? 0.0;
    return GestureDetector(
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
          widget.onAutomationLinkTap?.call('waveform');
        } else {
          widget.onAutomateParameter?.call('waveform');
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
              widget.onModulationAssign?.call('waveform', _amount);
              setState(() {
                _assigning = false;
                _amount = 0;
              });
              if (_linkActive) _pulseController.repeat(reverse: true);
            },
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => SizedBox(
          key: const ValueKey('phaser-waveform-selector'),
          width: 76,
          height: 40,
          child: Stack(
            children: [
              PopupMenuButton<int>(
                key: const ValueKey('phaser-waveform-menu'),
                tooltip: 'LFO waveform',
                padding: EdgeInsets.zero,
                color: const Color(0xFF22222E),
                onSelected: (value) =>
                    widget.onParameterChanged('waveform', value.toDouble()),
                itemBuilder: (context) => [
                  for (var i = 0; i < waveforms.length; i++)
                    PopupMenuItem<int>(
                      value: i,
                      height: 34,
                      child: Text(
                        waveforms[i],
                        style: TextStyle(
                          color: i == waveform ? accent : Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        waveforms[waveform],
                        style: TextStyle(
                          color: _linkActive
                              ? Color.lerp(Colors.white60, accent, _pulse.value)
                              : Colors.white60,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 1),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
              if ((widget.modulatedParams.contains('waveform') || _assigning) &&
                  shownAmount.abs() > 0)
                Positioned(
                  left: shownAmount < 0 ? null : 6,
                  right: shownAmount < 0 ? 6 : null,
                  bottom: 6,
                  width: 62 * shownAmount.abs().clamp(.05, 1.0),
                  child: const ColoredBox(
                    color: accent,
                    child: SizedBox(height: 2),
                  ),
                ),
              if (widget.automatedParams.contains('waveform'))
                const Positioned(
                  left: 3,
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
    );
  }
}
