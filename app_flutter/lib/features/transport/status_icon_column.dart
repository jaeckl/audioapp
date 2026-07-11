part of 'transport_bar.dart';

class _StatusIconColumn extends StatelessWidget {
  const _StatusIconColumn({
    required this.loopEnabled,
    required this.recordArmed,
    required this.recordingActive,
    required this.followActive,
    required this.followEnabled,
    required this.loopTooltip,
    required this.followTooltip,
    this.onLoopToggled,
    this.onRecordArmedChanged,
    this.onCancelRecording,
    this.onFollowPlayheadToggled,
  });

  final bool loopEnabled;
  final bool recordArmed;
  final bool recordingActive;
  final bool followActive;
  final bool followEnabled;
  final String loopTooltip;
  final String followTooltip;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<bool>? onRecordArmedChanged;
  final VoidCallback? onCancelRecording;
  final ValueChanged<bool>? onFollowPlayheadToggled;

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[
      _StatusIconButton(
        icon: loopEnabled ? Icons.loop : Icons.loop_outlined,
        tooltip: loopTooltip,
        accent: loopEnabled ? TransportBarTheme.accentLoop : null,
        onTap:
            onLoopToggled == null ? null : () => onLoopToggled!(!loopEnabled),
      ),
      _StatusIconButton(
        icon: recordingActive
            ? Icons.cancel_rounded
            : recordArmed
                ? Icons.fiber_manual_record
                : Icons.radio_button_unchecked,
        tooltip: recordingActive
            ? 'Cancel recording'
            : recordArmed
                ? 'Record armed — tap to disarm'
                : 'Arm selected track',
        accent: recordArmed || recordingActive
            ? TransportBarTheme.accentRecord
            : null,
        onTap: recordingActive
            ? onCancelRecording
            : onRecordArmedChanged == null
                ? null
                : () => onRecordArmedChanged!(!recordArmed),
      ),
      _StatusIconButton(
        icon: followEnabled ? Icons.my_location : Icons.location_searching,
        tooltip: followTooltip,
        accent: followActive ? TransportBarTheme.accentPlay : null,
        onTap: onFollowPlayheadToggled == null
            ? null
            : () => onFollowPlayheadToggled!(!followEnabled),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final slot in slots) Expanded(child: slot)],
    );
  }
}
