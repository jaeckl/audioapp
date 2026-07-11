part of 'sampler_device_panel.dart';

class _SamplerDevicePanelState extends State<SamplerDevicePanel> {
  late SamplerDeviceTab _tab;

  SamplerDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _durationSec {
    final beats = widget.sample?.durationBeats ?? 0;
    if (beats <= 0 || widget.bpm <= 0) return 1.0;
    return beats * 60.0 / widget.bpm;
  }

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant SamplerDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null &&
        widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final peaks = widget.sample?.waveformPeaks ?? const <double>[];

    return Material(
      color:
          widget.embeddedInCard ? Colors.transparent : SamplerDevicePanel.panel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.embeddedInCard ? 10 : 12,
          widget.embeddedInCard ? 4 : 8,
          10,
          6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildTabBody(peaks)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(List<double> peaks) {
    switch (_activeTab) {
      case SamplerDeviceTab.wave:
        return _WaveTab(
          device: widget.device,
          sampleName: widget.sample?.name,
          peaks: peaks,
          durationSec: _durationSec,
          onParameterChanged: widget.onParameterChanged,
          onPreview: widget.onPreview,
          onLoadSample: widget.onLoadSample,
          modulatedParams: widget.modulatedParams,
          automatedParams: widget.automatedParams,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
          automationLinkActive: widget.automationLinkActive,
          onAutomationLinkTap: widget.onAutomationLinkTap,
          onAutomateParameter: widget.onAutomateParameter,
          lfos: widget.lfos,
          modEdges: widget.modEdges,
        );
      case SamplerDeviceTab.tone:
        return _ToneTab(
          device: widget.device,
          knobSize: widget._knobSize,
          editor: widget._isEditor,
          onParameterChanged: widget.onParameterChanged,
          modulatedParams: widget.modulatedParams,
          automatedParams: widget.automatedParams,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
          automationLinkActive: widget.automationLinkActive,
          onAutomationLinkTap: widget.onAutomationLinkTap,
          onAutomateParameter: widget.onAutomateParameter,
        );
    }
  }
}
