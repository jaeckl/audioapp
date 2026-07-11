part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateFilterkeytracktoggle
    on _SubtractiveSynthDevicePanelState {
  Widget _filterKeyTrackToggle() {
    final active = widget.device.filterKeyTrack > 0.001;
    final color = active ? SubtractiveSynthDevicePanel.accent : Colors.white38;
    return Padding(
      padding: const EdgeInsets.only(top: 13),
      child: Tooltip(
        message: active
            ? 'Keyboard tracking affects filter cutoff'
            : 'Enable keyboard tracking for filter cutoff',
        child: Material(
          color: active
              ? SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            onTap: () => widget.onParameterChanged(
              'filterKeyTrack',
              active ? 0.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(5),
            child: SizedBox.square(
              dimension: 30,
              child: Icon(Icons.piano, size: 20, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
