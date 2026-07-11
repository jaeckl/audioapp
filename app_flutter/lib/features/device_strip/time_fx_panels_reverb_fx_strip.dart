part of 'time_fx_panels.dart';

class ReverbFxStrip extends StatelessWidget {
  const ReverbFxStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab = ReverbViewTab.tail,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });
  final ReverbDeviceSnapshot device;
  final TimeFxParameterChanged onParameterChanged;
  final ReverbViewTab selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final TimeFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => ReverbFxPanel(
        device: device,
        onParameterChanged: onParameterChanged,
        selectedTab: selectedTab,
        modulatedParams: modulatedParams,
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      );
}
