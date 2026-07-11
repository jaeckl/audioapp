part of 'device_strip_chrome.dart';

class DeviceStripChromeBindings {
  const DeviceStripChromeBindings({
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
    this.gainReductionDb = 0,
    this.inputLevel = 0,
    this.audioFxExpanded = false,
    this.noteFxExpanded = false,
    this.onToggleAudioFx,
    this.onToggleNoteFx,
  });

  final DeviceSnapshot device;
  final Color accentColor;
  final void Function(String parameterId, double value) onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final double gainReductionDb;
  final double inputLevel;
  final bool audioFxExpanded;
  final bool noteFxExpanded;
  final VoidCallback? onToggleAudioFx;
  final VoidCallback? onToggleNoteFx;
}
