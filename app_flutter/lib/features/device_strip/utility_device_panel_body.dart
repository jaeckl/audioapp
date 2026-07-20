part of 'utility_device_panel.dart';

class UtilityDevicePanelBody extends StatelessWidget {
  const UtilityDevicePanelBody({
    super.key,
    required this.device,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeLfoId,
    required this.onModulationAssign,
    required this.automationLinkActive,
    required this.onAutomationLinkTap,
    required this.onAutomateParameter,
  });

  final UtilityDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const _accent = UtilityDevicePanel.accent;

  /// Bitwig Tool-style face button (L- / Swap / R-).
  Widget _toolButton({
    required String label,
    required bool on,
    required String paramId,
    int flex = 1,
    bool expand = true,
  }) {
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onParameterChanged(paramId, on ? 0.0 : 1.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: on
              ? _accent.withValues(alpha: 0.22)
              : const Color(0xFF222229),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: on ? _accent.withValues(alpha: 0.55) : const Color(0xFF3A3A48),
          ),
        ),
        child: SizedBox(
          height: 30,
          width: expand ? null : double.infinity,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: on ? _accent : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
    if (!expand) return button;
    return Expanded(flex: flex, child: button);
  }

  Widget _knob(String label, double value, String paramId, {String? displayValue}) {
    return RotaryKnob(
      label: label,
      value: value,
      size: DeviceStripMetrics.dynamicsFxKnobSize,
      accentColor: _accent,
      parameterId: paramId,
      displayValue: displayValue,
      onChanged: (v) => onParameterChanged(paramId, v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final autopanOn = device.utilAutopan >= 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _toolButton(
                label: 'L−',
                on: device.utilInvertL >= 0.5,
                paramId: 'utilInvertL',
              ),
              const SizedBox(width: 5),
              _toolButton(
                label: 'Swap L/R',
                on: device.utilSwap >= 0.5,
                paramId: 'utilSwap',
                flex: 2,
              ),
              const SizedBox(width: 5),
              _toolButton(
                label: 'R−',
                on: device.utilInvertR >= 0.5,
                paramId: 'utilInvertR',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _toolButton(
            label: autopanOn ? 'Autopan On' : 'Autopan Off',
            on: autopanOn,
            paramId: 'utilAutopan',
            expand: false,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _knob(
                      'Width',
                      device.utilWidth,
                      'utilWidth',
                      displayValue: '${(device.utilWidth * 100).round()}%',
                    ),
                    _knob(
                      'Trim',
                      device.utilTrim,
                      'utilTrim',
                      displayValue: '${(device.utilTrim * 100).round()}%',
                    ),
                  ],
                ),
                if (autopanOn)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _knob(
                        'Rate',
                        device.utilAutopanRate,
                        'utilAutopanRate',
                        displayValue:
                            '${(0.1 + device.utilAutopanRate * 7.9).toStringAsFixed(1)} Hz',
                      ),
                      _knob(
                        'Depth',
                        device.utilAutopanDepth,
                        'utilAutopanDepth',
                        displayValue:
                            '${(device.utilAutopanDepth * 100).round()}%',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
