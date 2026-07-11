part of 'sampler_waveform_view.dart';

class _PlaybackModeSegments extends StatelessWidget {
  const _PlaybackModeSegments({
    required this.playbackMode,
    required this.accentColor,
    required this.onPlaybackModeChanged,
  });

  final int playbackMode;
  final Color accentColor;
  final ValueChanged<int> onPlaybackModeChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0;
                i < SamplerPlaybackIdentityBar._modes.length;
                i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              Expanded(
                child: _PlaybackSegment(
                  selected:
                      playbackMode == SamplerPlaybackIdentityBar._modes[i].id,
                  icon: SamplerPlaybackIdentityBar._modes[i].icon,
                  label: SamplerPlaybackIdentityBar._modes[i].label,
                  accentColor: accentColor,
                  onTap: () => onPlaybackModeChanged(
                      SamplerPlaybackIdentityBar._modes[i].id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
