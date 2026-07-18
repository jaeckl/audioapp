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
  String? _scopedDeviceId;

  EffectiveParameterKey? get _effectiveKey {
    if ((!widget.automationActive && !widget.modulationActive) ||
        (widget.deviceId ?? _scopedDeviceId) == null ||
        (widget.parameterId ?? widget.polarityParamId) == null) {
      return null;
    }
    return (
      deviceId: widget.deviceId ?? _scopedDeviceId!,
      parameterId: widget.parameterId ?? widget.polarityParamId!
    );
  }

  double get _displayValue {
    final key = _effectiveKey;
    return key == null
        ? widget.value
        : effectiveParameterMonitor.valueFor(key) ?? widget.value;
  }

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
    final key = _effectiveKey;
    if (key != null) effectiveParameterMonitor.register(key);
  }

  @override
  void didChangeDependencies() {
    final oldKey = _effectiveKey;
    super.didChangeDependencies();
    _scopedDeviceId = EffectiveParameterScope.maybeDeviceIdOf(context);
    final newKey = _effectiveKey;
    if (oldKey != newKey) {
      if (oldKey != null) effectiveParameterMonitor.unregister(oldKey);
      if (newKey != null) effectiveParameterMonitor.register(newKey);
    }
  }

  @override
  void didUpdateWidget(covariant RotaryKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKey =
        ((!oldWidget.automationActive && !oldWidget.modulationActive) ||
                (oldWidget.deviceId ?? _scopedDeviceId) == null ||
                (oldWidget.parameterId ?? oldWidget.polarityParamId) == null)
            ? null
            : (
                deviceId: oldWidget.deviceId ?? _scopedDeviceId!,
                parameterId: oldWidget.parameterId ?? oldWidget.polarityParamId!
              );
    final newKey = _effectiveKey;
    if (oldKey != newKey) {
      if (oldKey != null) effectiveParameterMonitor.unregister(oldKey);
      if (newKey != null) effectiveParameterMonitor.register(newKey);
    }
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
    final key = _effectiveKey;
    if (key != null) effectiveParameterMonitor.unregister(key);
    _pulseController.dispose();
    super.dispose();
  }

  // --- Normal knob drag (changes value) ---

  // --- Connect-mode long-press modulation assignment ---

  @override
  Widget build(BuildContext context) {
    if (_effectiveKey == null) return _buildContent(context);
    return AnimatedBuilder(
      animation: effectiveParameterMonitor,
      builder: (context, _) => _buildContent(context),
    );
  }
}
