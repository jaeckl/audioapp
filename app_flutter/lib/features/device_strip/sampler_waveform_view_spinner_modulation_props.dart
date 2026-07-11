part of 'sampler_waveform_view.dart';

class SpinnerModulationProps {
  const SpinnerModulationProps({
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
    this.rootPitchPolarity = ModulatorPolarity.bipolar,
    this.rootFineTunePolarity = ModulatorPolarity.bipolar,
  });

  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final ModulatorPolarity rootPitchPolarity;
  final ModulatorPolarity rootFineTunePolarity;

  static const none = SpinnerModulationProps();
}
