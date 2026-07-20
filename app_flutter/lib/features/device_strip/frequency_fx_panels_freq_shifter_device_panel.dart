part of 'frequency_fx_panels.dart';

class FreqShifterDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['frequency_shifter'];
  const FreqShifterDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFFC77DFF);
  static const containerTabs = <DeviceTabSpec>[];

  /// Ring mod — sideband hero + plate (not Phaser rails).
  static const double designWidth = 300;

  final FrequencyShifterDeviceSnapshot device;
  final FrequencyFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final FrequencyFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  double get _carrierHz {
    final coarse = (device.ffxShift.clamp(0.0, 1.0) - 0.5) * 4000.0;
    final fine = (device.ffxFine.clamp(0.0, 1.0) - 0.5) * 100.0;
    return coarse + fine;
  }

  @override
  Widget build(BuildContext context) {
    final shiftNorm = device.ffxShift.clamp(0.0, 1.0);
    final fineNorm = device.ffxFine.clamp(0.0, 1.0);
    final mixNorm = device.ffxMix.clamp(0.0, 1.0);
    final toneNorm = device.ffxTone.clamp(0.0, 1.0);
    final fbNorm = device.ffxFeedback.clamp(0.0, 1.0);
    final carrier = _carrierHz;

    return FilterSectionLayout(
      modeSelector: SizedBox(
        height: DevicePanelTheme.modeRowHeight,
        child: Center(
          child: Text(
            'RING',
            style: TextStyle(
              color: accent.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      preview: IgnorePointer(
        child: _RingModSidebandPreview(
          carrierHz: carrier,
          mix: mixNorm,
          tone: toneNorm,
          feedback: fbNorm,
          accent: accent,
        ),
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _knob(
                label: 'SHIFT',
                value: shiftNorm,
                paramId: 'ffxShift',
                accent: accent,
                onParameterChanged: onParameterChanged,
                modulatedParams: modulatedParams,
                automatedParams: automatedParams,
                modulationAmounts: modulationAmounts,
                connectModeLfoId: connectModeLfoId,
                onModulationAssign: onModulationAssign,
                automationLinkActive: automationLinkActive,
                onAutomationLinkTap: onAutomationLinkTap,
                onAutomateParameter: onAutomateParameter,
                displayValue: _fmtSignedHz((shiftNorm - 0.5) * 4000.0),
              ),
              _knob(
                label: 'FINE',
                value: fineNorm,
                paramId: 'ffxFine',
                accent: accent,
                onParameterChanged: onParameterChanged,
                modulatedParams: modulatedParams,
                automatedParams: automatedParams,
                modulationAmounts: modulationAmounts,
                connectModeLfoId: connectModeLfoId,
                onModulationAssign: onModulationAssign,
                automationLinkActive: automationLinkActive,
                onAutomationLinkTap: onAutomationLinkTap,
                onAutomateParameter: onAutomateParameter,
                displayValue: _fmtSignedHz((fineNorm - 0.5) * 100.0),
              ),
              _knob(
                label: 'MIX',
                value: mixNorm,
                paramId: 'ffxMix',
                accent: accent,
                onParameterChanged: onParameterChanged,
                modulatedParams: modulatedParams,
                automatedParams: automatedParams,
                modulationAmounts: modulationAmounts,
                connectModeLfoId: connectModeLfoId,
                onModulationAssign: onModulationAssign,
                automationLinkActive: automationLinkActive,
                onAutomationLinkTap: onAutomationLinkTap,
                onAutomateParameter: onAutomateParameter,
                displayValue: '${(mixNorm * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _knob(
                label: 'TONE',
                value: toneNorm,
                paramId: 'ffxTone',
                accent: accent,
                onParameterChanged: onParameterChanged,
                modulatedParams: modulatedParams,
                automatedParams: automatedParams,
                modulationAmounts: modulationAmounts,
                connectModeLfoId: connectModeLfoId,
                onModulationAssign: onModulationAssign,
                automationLinkActive: automationLinkActive,
                onAutomationLinkTap: onAutomationLinkTap,
                onAutomateParameter: onAutomateParameter,
                displayValue: '${(toneNorm * 100).round()}%',
              ),
              _knob(
                label: 'FB',
                value: fbNorm,
                paramId: 'ffxFeedback',
                accent: accent,
                onParameterChanged: onParameterChanged,
                modulatedParams: modulatedParams,
                automatedParams: automatedParams,
                modulationAmounts: modulationAmounts,
                connectModeLfoId: connectModeLfoId,
                onModulationAssign: onModulationAssign,
                automationLinkActive: automationLinkActive,
                onAutomationLinkTap: onAutomationLinkTap,
                onAutomateParameter: onAutomateParameter,
                displayValue: '${(fbNorm * 100).round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtSignedHz(double hz) {
    if (hz.abs() < 0.5) return '0 Hz';
    final sign = hz > 0 ? '+' : '';
    return '$sign${hz.toStringAsFixed(0)} Hz';
  }
}
