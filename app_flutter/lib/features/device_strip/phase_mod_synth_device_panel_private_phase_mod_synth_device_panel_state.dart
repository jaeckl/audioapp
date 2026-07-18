part of 'phase_mod_synth_device_panel.dart';

class _PhaseModSynthDevicePanelState extends State<PhaseModSynthDevicePanel> {
  late PhaseModSynthDeviceTab _tab;
  int _selectedOperator = 0;

  PhaseModSynthDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  // Scaled down knob sizes with ample breathing room to prevent touching borders
  double get _knobSize => widget.density == PhaseModSynthPanelDensity.editor
      ? DeviceKnobSizes.editor * 0.9
      : 40.0; // standard scaled down size

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
    double labelGap =
        0, // decreased label gap to prevent touching container borders
  }) {
    final modAmount = paramId != null ? modulationAmounts[paramId] ?? 0.0 : 0.0;
    return RotaryKnob(
      label: label,
      value: value,
      onChanged: onChanged,
      displayValue: displayValue,
      size: size ?? _knobSize,
      labelGap: labelGap,
      accentColor: PhaseModSynthDevicePanel.accent,
      modulationActive:
          paramId != null && widget.modulatedParams.contains(paramId),
      automationActive:
          paramId != null && widget.automatedParams.contains(paramId),
      modulationAmount: modAmount,
      parameterId: paramId,
      connectModeActive: paramId != null && connectModeLfoId != null,
      onModulationAssign: paramId != null && onModulationAssign != null
          ? (a) => onModulationAssign(paramId, a)
          : null,
      linkModeActive: paramId != null && widget.automationLinkActive,
      linkModeAccent: PhaseModSynthDevicePanel.accent,
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
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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

  Widget _borderlessDropdown<T>({
    required T value,
    required List<T> items,
    required List<String> itemLabels,
    required ValueChanged<T> onChanged,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 24,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              dropdownColor: const Color(0xFF1C1C24),
              style: const TextStyle(
                color: PhaseModSynthDevicePanel.accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
              icon: const Icon(Icons.expand_more,
                  color: PhaseModSynthDevicePanel.accent, size: 12),
              items: List.generate(items.length, (i) {
                return DropdownMenuItem<T>(
                  value: items[i],
                  child: Text(itemLabels[i],
                      style: const TextStyle(fontSize: 10.5)),
                );
              }),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  double _opParam(int opIndex, String param) {
    switch (opIndex) {
      case 0:
        return switch (param) {
          'ratio' => widget.device.pmOp1Ratio,
          'fine' => widget.device.pmOp1Fine,
          'level' => widget.device.pmOp1Level,
          'wave' => widget.device.pmOp1Wave,
          'attack' => widget.device.pmOp1Attack,
          'decay' => widget.device.pmOp1Decay,
          'sustain' => widget.device.pmOp1Sustain,
          'release' => widget.device.pmOp1Release,
          'velSense' => widget.device.pmOp1VelSense,
          'keyTrack' => widget.device.pmOp1KeyTrack,
          _ => 0.0,
        };
      case 1:
        return switch (param) {
          'ratio' => widget.device.pmOp2Ratio,
          'fine' => widget.device.pmOp2Fine,
          'level' => widget.device.pmOp2Level,
          'wave' => widget.device.pmOp2Wave,
          'attack' => widget.device.pmOp2Attack,
          'decay' => widget.device.pmOp2Decay,
          'sustain' => widget.device.pmOp2Sustain,
          'release' => widget.device.pmOp2Release,
          'velSense' => widget.device.pmOp2VelSense,
          'keyTrack' => widget.device.pmOp2KeyTrack,
          _ => 0.0,
        };
      case 2:
        return switch (param) {
          'ratio' => widget.device.pmOp3Ratio,
          'fine' => widget.device.pmOp3Fine,
          'level' => widget.device.pmOp3Level,
          'wave' => widget.device.pmOp3Wave,
          'attack' => widget.device.pmOp3Attack,
          'decay' => widget.device.pmOp3Decay,
          'sustain' => widget.device.pmOp3Sustain,
          'release' => widget.device.pmOp3Release,
          'velSense' => widget.device.pmOp3VelSense,
          'keyTrack' => widget.device.pmOp3KeyTrack,
          _ => 0.0,
        };
      case 3:
        return switch (param) {
          'ratio' => widget.device.pmOp4Ratio,
          'fine' => widget.device.pmOp4Fine,
          'level' => widget.device.pmOp4Level,
          'wave' => widget.device.pmOp4Wave,
          'attack' => widget.device.pmOp4Attack,
          'decay' => widget.device.pmOp4Decay,
          'sustain' => widget.device.pmOp4Sustain,
          'release' => widget.device.pmOp4Release,
          'velSense' => widget.device.pmOp4VelSense,
          'keyTrack' => widget.device.pmOp4KeyTrack,
          _ => 0.0,
        };
      default:
        return 0.0;
    }
  }

  String _opParamId(int opIndex, String param) {
    return 'pmOp${opIndex + 1}$param';
  }

  @override
  void initState() {
    super.initState();
    _tab = PhaseModSynthDeviceTab.mix;
  }

  @override
  void didUpdateWidget(covariant PhaseModSynthDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null &&
        widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildTabContent();
    if (widget.density == PhaseModSynthPanelDensity.editor) {
      return Column(
        children: [
          DeviceTabBar(
            tabs: PhaseModSynthDevicePanel.containerTabs,
            selectedIndex: _activeTab.index,
            accentColor: PhaseModSynthDevicePanel.accent,
            onSelected: (i) {
              final tab = PhaseModSynthDeviceTab.values[i];
              widget.onTabChanged?.call(tab);
              setState(() => _tab = tab);
            },
          ),
          Expanded(child: body),
        ],
      );
    }
    return body;
  }

  Widget _buildTabContent() {
    return switch (_activeTab) {
      PhaseModSynthDeviceTab.mix => _mixTab(),
      PhaseModSynthDeviceTab.op => _opTab(),
      PhaseModSynthDeviceTab.tone => _toneTab(),
    };
  }

  // ── MIX tab ──────────────────────────────────────────────────────────

  // ── OP tab ────────────────────────────────────────────────────────────

  // ── TONE tab ──────────────────────────────────────────────────────────
}
