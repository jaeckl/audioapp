part of 'wavetable_synth_device_panel.dart';

class _WavetableSynthDevicePanelState extends State<WavetableSynthDevicePanel> {
  late WavetableSynthDeviceTab _tab;

  WavetableSynthDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _knobSize => widget.density == WavetablePanelDensity.editor
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
      accentColor: WavetableSynthDevicePanel.accent,
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
    bool showBorder = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(4),
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(4),
        border: showBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
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
    _tab = WavetableSynthDeviceTab.source;
  }

  @override
  void didUpdateWidget(covariant WavetableSynthDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null &&
        widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_activeTab) {
      WavetableSynthDeviceTab.source => _oscTab(),
      WavetableSynthDeviceTab.tone => _filterTab(),
      WavetableSynthDeviceTab.voice => _voiceTab(),
    };

    if (widget.embeddedInCard) {
      return body;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeviceTabBar(
          tabs: WavetableSynthDevicePanel.containerTabs,
          selectedIndex: _activeTab.index,
          accentColor: WavetableSynthDevicePanel.accent,
          onSelected: (i) {
            final tab = WavetableSynthDeviceTab.values[i];
            setState(() => _tab = tab);
            widget.onTabChanged?.call(tab);
          },
        ),
        Expanded(child: body),
      ],
    );
  }

  String _formatOctave(double normalized) {
    final oct = ((normalized - 0.5) * 4).round();
    if (oct == 0) return '0';
    return oct > 0 ? '+$oct' : '$oct';
  }

  String _formatSemitone(double normalized) {
    final semi = ((normalized - 0.5) * 48).round();
    if (semi == 0) return '0';
    return semi > 0 ? '+$semi' : '$semi';
  }

  String _formatFine(double normalized) {
    final cents = ((normalized - 0.5) * 100).round();
    if (cents == 0) return '0\u00A2';
    return cents > 0 ? '+$cents\u00A2' : '$cents\u00A2';
  }
}
