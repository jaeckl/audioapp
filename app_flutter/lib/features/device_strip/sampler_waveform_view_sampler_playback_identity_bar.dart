part of 'sampler_waveform_view.dart';

class SamplerPlaybackIdentityBar extends StatelessWidget {
  const SamplerPlaybackIdentityBar({
    super.key,
    required this.rootPitch,
    required this.rootFineTune,
    required this.playbackMode,
    required this.accentColor,
    required this.onRootPitchChanged,
    required this.onRootFineTuneChanged,
    required this.onPlaybackModeChanged,
    this.onPreview,
    this.previewEnabled = true,
    this.modulation = SpinnerModulationProps.none,
  });

  final int rootPitch;
  final double rootFineTune;
  final int playbackMode;
  final Color accentColor;
  final ValueChanged<int> onRootPitchChanged;
  final ValueChanged<double> onRootFineTuneChanged;
  final ValueChanged<int> onPlaybackModeChanged;
  final VoidCallback? onPreview;
  final bool previewEnabled;
  final SpinnerModulationProps modulation;

  static const controlHeight = 48.0;

  static const _modes = <({int id, IconData icon, String label})>[
    (id: 0, icon: Icons.play_arrow_rounded, label: 'Shot'),
    (id: 1, icon: Icons.loop_rounded, label: 'Loop'),
    (id: 2, icon: Icons.replay_rounded, label: 'Rev'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROOT',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                SamplerRootKeyChip(
                  rootPitch: rootPitch,
                  accentColor: accentColor,
                  onChanged: onRootPitchChanged,
                  showFooterLabel: false,
                  fixedHeight: controlHeight,
                  modulation: modulation,
                ),
              ],
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TUNE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                SamplerFineTuneChip(
                  rootFineTune: rootFineTune,
                  accentColor: accentColor,
                  onChanged: onRootFineTuneChanged,
                  fixedHeight: controlHeight,
                  modulation: modulation,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 6, 0),
              child: SizedBox(
                height: controlHeight,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'PLAY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: controlHeight,
                    child: _PlaybackModeSegments(
                      playbackMode: playbackMode,
                      accentColor: accentColor,
                      onPlaybackModeChanged: onPlaybackModeChanged,
                    ),
                  ),
                ],
              ),
            ),
            if (onPreview != null)
              SizedBox(
                height: controlHeight,
                width: 40,
                child: IconButton(
                  tooltip: 'Preview at root key',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: previewEnabled ? onPreview : null,
                  icon: Icon(
                    Icons.play_arrow_rounded,
                    size: 24,
                    color: previewEnabled ? accentColor : Colors.white24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
