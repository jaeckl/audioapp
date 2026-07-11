part of 'phase_mod_synth_device_panel.dart';

extension _PhaseModSynthDevicePanelStateToggleknob
    on _PhaseModSynthDevicePanelState {
  Widget _toggleKnob({
    required String label,
    required double value,
    required String paramId,
    required String onLabel,
    required String offLabel,
  }) {
    final isOn = value >= 0.5;
    final size = _knobSize * 0.95;
    return GestureDetector(
      onTap: () => widget.onParameterChanged(paramId, isOn ? 0.0 : 1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isOn
              ? PhaseModSynthDevicePanel.accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOn
                ? PhaseModSynthDevicePanel.accent.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isOn ? onLabel : offLabel,
              style: TextStyle(
                color: isOn ? PhaseModSynthDevicePanel.accent : Colors.white54,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 7.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
