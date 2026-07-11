part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateFlattoggle
    on _SubtractiveSynthDevicePanelState {
  Widget _flatToggle({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? SubtractiveSynthDevicePanel.accent : Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
