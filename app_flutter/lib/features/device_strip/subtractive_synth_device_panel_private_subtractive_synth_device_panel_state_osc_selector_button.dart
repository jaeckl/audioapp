part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateOscselectorbutton
    on _SubtractiveSynthDevicePanelState {
  Widget _oscSelectorButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.22)
          : Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? SubtractiveSynthDevicePanel.accent
                  : Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ),
    );
  }
}
