part of 'time_fx_panels.dart';

class _ReverbResponseEditorState extends State<_ReverbResponseEditor>
    with SingleTickerProviderStateMixin {
  String? _dragParameter;
  String? _assignmentParameter;
  double _assignmentStartY = 0;
  double _assignmentAmount = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  bool get _pulseActive => widget.connectModeActive || widget.linkModeActive;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse = Tween<double>(begin: .08, end: .3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ReverbResponseEditor oldWidget) {
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

  String _parameterAt(Offset position, Size size) {
    if (widget.view == ReverbViewTab.tail) {
      final preX = 12 + widget.device.preDelay * 55;
      final decayX = 70 + widget.device.decay * (size.width - 82);
      return (position.dx - preX).abs() < (position.dx - decayX).abs()
          ? 'preDelay'
          : 'decay';
    }
    if (widget.view == ReverbViewTab.mod) return 'modulation';
    final lowX = 12 + widget.device.lowCut * 58;
    final highX = size.width - 12 - (1 - widget.device.highCut) * 58;
    final duckX = 12 + widget.device.ducking * (size.width - 24);
    final dampingX = 70 + widget.device.damping * (size.width - 140);
    final distances = <String, double>{
      'lowCut': (position - Offset(lowX, size.height * .3)).distance,
      'highCut': (position - Offset(highX, size.height * .3)).distance,
      'ducking': (position - Offset(duckX, size.height - 11)).distance,
      'damping': (position - Offset(dampingX, size.height * .46)).distance,
    };
    return distances.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  void _updateParameter(String parameter, Offset position, Size size) {
    final value = switch (parameter) {
      'preDelay' => ((position.dx - 12) / 55).clamp(0.0, 1.0),
      'decay' => ((position.dx - 70) / (size.width - 82)).clamp(0.0, 1.0),
      'lowCut' => ((position.dx - 12) / 58).clamp(0.0, 1.0),
      'highCut' => (1 - (size.width - 12 - position.dx) / 58).clamp(0.0, 1.0),
      'ducking' => ((position.dx - 12) / (size.width - 24)).clamp(0.0, 1.0),
      'damping' => ((position.dx - 70) / (size.width - 140)).clamp(0.0, 1.0),
      'modulation' => ((position.dx - 12) / (size.width - 24)).clamp(0.0, 1.0),
      _ => 0.0,
    };
    widget.onParameterChanged(parameter, value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (details) {
              if (widget.linkModeActive) {
                HapticFeedback.mediumImpact();
                widget.onAutomationLinkTap
                    ?.call(_parameterAt(details.localPosition, size));
              }
            },
            onHorizontalDragStart: widget.connectModeActive ||
                    widget.linkModeActive
                ? null
                : (details) =>
                    _dragParameter = _parameterAt(details.localPosition, size),
            onHorizontalDragUpdate:
                widget.connectModeActive || widget.linkModeActive
                    ? null
                    : (details) => _updateParameter(
                          _dragParameter ??
                              _parameterAt(details.localPosition, size),
                          details.localPosition,
                          size,
                        ),
            onHorizontalDragEnd: (_) => _dragParameter = null,
            onLongPressStart: (details) {
              final parameter = _parameterAt(details.localPosition, size);
              HapticFeedback.mediumImpact();
              if (widget.connectModeActive) {
                _pulseController.stop();
                setState(() {
                  _assignmentParameter = parameter;
                  _assignmentStartY = details.localPosition.dy;
                  _assignmentAmount = 0;
                });
              } else {
                widget.onAutomateParameter?.call(parameter);
              }
            },
            onLongPressMoveUpdate: widget.connectModeActive
                ? (details) => setState(() {
                      _assignmentAmount =
                          ((_assignmentStartY - details.localPosition.dy) / 80)
                              .clamp(-1.0, 1.0);
                    })
                : null,
            onLongPressEnd: widget.connectModeActive
                ? (_) {
                    if (_assignmentParameter != null) {
                      widget.onModulationAssign
                          ?.call(_assignmentParameter!, _assignmentAmount);
                    }
                    _pulseController.reset();
                    if (_pulseActive) {
                      _pulseController.repeat(reverse: true);
                    }
                    setState(() {
                      _assignmentParameter = null;
                      _assignmentAmount = 0;
                    });
                  }
                : null,
            child: Container(
              key: const ValueKey('reverb-response-editor'),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  widget.accent.withValues(
                    alpha: _pulseActive ? _pulse.value : 0,
                  ),
                  const Color(0xFF050508),
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _pulseActive
                      ? widget.accent.withValues(alpha: .65)
                      : Colors.white.withValues(alpha: .1),
                ),
              ),
              child: EffectiveParameterValuesBuilder(
                fallbackValues: {
                  'modeMorph': widget.device.modeMorph / 3,
                  'preDelay': widget.device.preDelay,
                  'decay': widget.device.decay,
                  'lowCut': widget.device.lowCut,
                  'highCut': widget.device.highCut,
                  'damping': widget.device.damping,
                  'ducking': widget.device.ducking,
                  'modulation': widget.device.modulation,
                },
                activeParameterIds: widget.automatedParams,
                builder: (context, liveValues) => CustomPaint(
                  painter: _ReverbResponsePainter(
                    view: widget.view,
                    device: widget.device,
                    liveValues: liveValues,
                    accent: widget.accent,
                    modulatedParams: widget.modulatedParams,
                    automatedParams: widget.automatedParams,
                    modulationAmounts: widget.modulationAmounts,
                    assignmentParameter: _assignmentParameter,
                    assignmentAmount: _assignmentAmount,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
