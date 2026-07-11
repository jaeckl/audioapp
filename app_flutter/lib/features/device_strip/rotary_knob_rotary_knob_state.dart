part of 'rotary_knob.dart';

class _RotaryKnobState extends State<RotaryKnob> with SingleTickerProviderStateMixin {
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
    final oldPulseActive = oldWidget.connectModeActive || oldWidget.linkModeActive;
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

  // --- Connect-mode long-press modulation assignment ---

  @override
  Widget build(BuildContext context) => _buildContent(context);

}
