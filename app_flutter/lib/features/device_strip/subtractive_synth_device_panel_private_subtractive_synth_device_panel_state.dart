part of 'subtractive_synth_device_panel.dart';

class _SubtractiveSynthDevicePanelState
    extends State<SubtractiveSynthDevicePanel> {
  late SubtractiveDeviceTab _tab;
  int _selectedOscillator = 0;

  SubtractiveDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _knobSize => widget.density == SubtractivePanelDensity.editor
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
      accentColor: SubtractiveSynthDevicePanel.accent,
      modulationActive:
          paramId != null && widget.modulatedParams.contains(paramId),
      automationActive:
          paramId != null && widget.automatedParams.contains(paramId),
      modulationAmount: modAmount,
      polarityParamId: paramId,
      deviceId: widget.device.id,
      lfos: widget.lfos,
      modEdges: widget.modEdges,
      connectModeLfoId: connectModeLfoId,
      connectModeActive: paramId != null && connectModeLfoId != null,
      onModulationAssign: paramId != null && onModulationAssign != null
          ? (a) => onModulationAssign(paramId, a)
          : null,
      linkModeActive: paramId != null && widget.automationLinkActive,
      linkModeAccent: LibraryTheme.accentAutomation,
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
    PanelVariant variant = PanelVariant.screen,
    bool showBorder = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(4),
  }) {
    final Color fill = switch (variant) {
      PanelVariant.screen => const Color(0xFF121218),
      PanelVariant.elevated => const Color(0xFF16161E),
      PanelVariant.subtle => const Color(0xFF181821),
      PanelVariant.flat => const Color(0xFF1A1A24),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
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

  @override
  void initState() {
    super.initState();
    _tab = SubtractiveDeviceTab.osc;
  }

  @override
  void didUpdateWidget(covariant SubtractiveSynthDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null &&
        widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_activeTab) {
      SubtractiveDeviceTab.osc => _oscTabV2(),
      SubtractiveDeviceTab.filter => _toneTab(),
      SubtractiveDeviceTab.amp => _ampTab(),
    };

    if (widget.embeddedInCard) {
      return body;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeviceTabBar(
          tabs: SubtractiveSynthDevicePanel.containerTabs,
          selectedIndex: _activeTab.index,
          accentColor: SubtractiveSynthDevicePanel.accent,
          onSelected: (i) {
            final tab = SubtractiveDeviceTab.values[i];
            setState(() => _tab = tab);
            widget.onTabChanged?.call(tab);
          },
        ),
        Expanded(child: body),
      ],
    );
  }

  // ignore: unused_element
  // Kept temporarily as a parameter-layout reference while Filter/Amp migration settles.
  // ignore: unused_element
  Widget _borderlessDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF1C1C24),
        style: const TextStyle(
          color: SubtractiveSynthDevicePanel.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        icon: const Icon(Icons.expand_more,
            color: SubtractiveSynthDevicePanel.accent, size: 14),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
