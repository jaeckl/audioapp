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
  static const _polarityLabels = ['Off', 'Invert L', 'Invert R', 'Invert Both'];

  Widget _miniToggle(String label, bool on, String paramId) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onParameterChanged(paramId, on ? 0.0 : 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: on
                ? _accent.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                label,
                style: TextStyle(
                  color: on ? _accent : Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _polarityIndex(double value) {
    if (value >= 0.83) return 3;
    if (value >= 0.5) return 2;
    if (value >= 0.16) return 1;
    return 0;
  }

  double _polarityValue(int index) => switch (index) {
        1 => 0.33,
        2 => 0.66,
        3 => 1.0,
        _ => 0.0,
      };

  Widget _polarityCombo() {
    final index = _polarityIndex(device.utilPolarity);
    return SizedBox(
      height: 28,
      child: PopupMenuButton<int>(
        key: ValueKey('utility-polarity-$index'),
        tooltip: 'Polarity',
        padding: EdgeInsets.zero,
        color: const Color(0xFF22222E),
        onSelected: (i) => onParameterChanged('utilPolarity', _polarityValue(i)),
        itemBuilder: (context) => [
          for (var i = 0; i < _polarityLabels.length; i++)
            PopupMenuItem<int>(
              value: i,
              height: 34,
              child: Text(
                _polarityLabels[i],
                style: TextStyle(
                  color: i == index ? _accent : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _polarityLabels[index].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .25,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _knob(String label, double value, String paramId) {
    return RotaryKnob(
      label: label,
      value: value,
      size: DeviceStripMetrics.dynamicsFxKnobSize,
      accentColor: _accent,
      parameterId: paramId,
      onChanged: (v) => onParameterChanged(paramId, v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final autopanOn = device.utilAutopan >= 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _miniToggle('Mono', device.utilMono >= 0.5, 'utilMono'),
              const SizedBox(width: 6),
              _miniToggle('Swap', device.utilSwap >= 0.5, 'utilSwap'),
              const SizedBox(width: 6),
              _miniToggle('Auto', autopanOn, 'utilAutopan'),
            ],
          ),
          const SizedBox(height: 8),
          _polarityCombo(),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _knob('Trim', device.utilTrim, 'utilTrim'),
                  if (autopanOn)
                    _knob('Rate', device.utilAutopanRate, 'utilAutopanRate'),
                  if (autopanOn)
                    _knob('Depth', device.utilAutopanDepth, 'utilAutopanDepth'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
