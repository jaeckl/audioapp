part of 'bass_synth_device_panel.dart';

class _BassSynthDevicePanelState extends State<BassSynthDevicePanel> {
  late BassSynthDeviceTab _tab;
  double _octDragStartY = 0;
  int _octDragStartValue = 0;

  BassSynthDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _knobSize => widget.density == BassPanelDensity.editor
      ? DeviceKnobSizes.editor
      : DeviceKnobSizes.strip;

  Widget _knob({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    String? displayValue,
    double? size,
    String? paramId,
    Map<String, double> modulationAmounts = const {},
    int? connectModeLfoId,
    void Function(String paramId, double amount)? onModulationAssign,
    double labelGap = 3,
  }) {
    final modAmount = paramId != null ? modulationAmounts[paramId] ?? 0.0 : 0.0;
    return RotaryKnob(
      label: label,
      value: value,
      onChanged: onChanged,
      displayValue: displayValue,
      size: size ?? _knobSize,
      labelGap: labelGap,
      accentColor: BassSynthDevicePanel.accent,
      modulationActive:
          paramId != null && widget.modulatedParams.contains(paramId),
      automationActive:
          paramId != null && widget.automatedParams.contains(paramId),
      modulationAmount: modAmount,
      connectModeActive: paramId != null && connectModeLfoId != null,
      onModulationAssign: paramId != null && onModulationAssign != null
          ? (a) => onModulationAssign(paramId, a)
          : null,
      linkModeActive: paramId != null && widget.automationLinkActive,
      linkModeAccent: const Color(0xFFB48CFF),
      onLinkTap: paramId != null && widget.onAutomationLinkTap != null
          ? () => widget.onAutomationLinkTap!(paramId)
          : null,
      onAutomateRequest: paramId != null && widget.onAutomateParameter != null
          ? () => widget.onAutomateParameter!(paramId)
          : null,
    );
  }

  Widget _panelBox({
    required Widget child,
    Color color = const Color(0xFF121218),
    bool showBorder = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(4),
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: showBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }

  /// Section label like "OSCILLATOR" or "AMP"
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tab = BassSynthDeviceTab.tone;
  }

  @override
  void didUpdateWidget(covariant BassSynthDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null &&
        widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildTabContent();
    return body;
  }

  Widget _buildTabContent() {
    return switch (_activeTab) {
      BassSynthDeviceTab.tone => _toneTab(),
      BassSynthDeviceTab.filter => _filterTab(),
    };
  }

  // ── TONE TAB ──────────────────────────────────────────────
  //
  // Layout: Row with two columns
  //   LEFT  — OSCILLATOR (knob row) + AMP (env preview + A/S/R) stacked
  //   RIGHT — PERFORMANCE column (Glide + Vel stacked vertically)
  /// Amp envelope shape preview for the TONE tab.
// ── FILTER TAB ──────────────────────────────────────────────
  //
  // Layout: Row with two columns
  //   LEFT  — FILTER CURVE preview + FILTER controls (Cutoff, Res, Env Amt, Decay)
  //   RIGHT — SATURATION column (Drive + Squash stacked vertically)
// ── Int octave slot ────────────────────────────────────────
  //
  // Layout exactly mirrors RotaryKnob:
  //   [control body same height as knob SizedBox]
  //   [gap]
  //   [label below with same fontSize/color/weight]
}
