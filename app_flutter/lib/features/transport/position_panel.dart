part of 'transport_bar.dart';

class _PositionPanel extends StatelessWidget {
  const _PositionPanel({
    required this.playing,
    required this.positionPrimary,
    required this.positionSecondary,
    this.recordingTrackName,
    this.recordingInputLevel = 0,
    required this.metronomeEnabled,
    required this.metronomeLevel,
    required this.countInBars,
    required this.loopEnabled,
    required this.recordArmed,
    required this.recordingActive,
    this.recordingModeLabel,
    required this.followActive,
    required this.followEnabled,
    required this.loopTooltip,
    required this.followTooltip,
    this.onPlay,
    this.onStop,
    this.onJumpToStart,
    this.onLoopToggled,
    this.onRecordArmedChanged,
    this.onCancelRecording,
    this.onFollowPlayheadToggled,
    this.onMetronomeChanged,
  });

  final bool playing;
  final String positionPrimary;
  final String positionSecondary;
  final String? recordingTrackName;
  final double recordingInputLevel;
  final bool metronomeEnabled;
  final double metronomeLevel;
  final int countInBars;
  final bool loopEnabled;
  final bool recordArmed;
  final bool recordingActive;
  final String? recordingModeLabel;
  final bool followActive;
  final bool followEnabled;
  final String loopTooltip;
  final String followTooltip;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;
  final VoidCallback? onJumpToStart;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<bool>? onRecordArmedChanged;
  final VoidCallback? onCancelRecording;
  final ValueChanged<bool>? onFollowPlayheadToggled;
  final void Function(bool, double, int)? onMetronomeChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: TransportBarTheme.statusIconHit,
          child: _StatusIconColumn(
            loopEnabled: loopEnabled,
            recordArmed: recordArmed,
            recordingActive: recordingActive,
            followActive: followActive,
            followEnabled: followEnabled,
            loopTooltip: loopTooltip,
            followTooltip: followTooltip,
            onLoopToggled: onLoopToggled,
            onRecordArmedChanged: onRecordArmedChanged,
            onCancelRecording: onCancelRecording,
            onFollowPlayheadToggled: onFollowPlayheadToggled,
          ),
        ),
        Row(
          children: [
            _JumpToStartButton(onPressed: onJumpToStart),
            _InlinePlayStop(
              playing: playing,
              onPlay: onPlay,
              onStop: onStop,
            ),
            _InlineMetronomeButton(
              enabled: metronomeEnabled,
              level: metronomeLevel,
              countInBars: countInBars,
              onChanged: onMetronomeChanged,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TransportBarTheme.cardInnerPaddingH,
                  TransportBarTheme.cardInnerPaddingV,
                  TransportBarTheme.statusIconHit + 4,
                  TransportBarTheme.cardInnerPaddingV,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'POSITION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: TransportBarTheme.textMuted,
                            fontSize: 9,
                            letterSpacing: 0.6,
                          ),
                    ),
                    Row(
                      children: [
                        Text(
                          positionPrimary,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: TransportBarTheme.textPrimary,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          recordingActive
                              ? (recordingModeLabel ??
                                  recordingTrackName ??
                                  'REC')
                              : positionSecondary,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: TransportBarTheme.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                        ),
                      ],
                    ),
                    if (recordingActive) ...[
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          value: recordingInputLevel.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            TransportBarTheme.accentRecord,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
