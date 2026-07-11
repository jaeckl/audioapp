part of 'transport_bar.dart';

class _InlinePlayStop extends StatelessWidget {
  const _InlinePlayStop({
    required this.playing,
    this.onPlay,
    this.onStop,
  });

  final bool playing;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final active = playing;
    return Semantics(
      button: true,
      label: active ? 'Stop' : 'Play',
      child: Material(
        color: active
            ? TransportBarTheme.accentPlay.withValues(alpha: 0.16)
            : Colors.transparent,
        child: InkWell(
          onTap: active ? onStop : onPlay,
          child: SizedBox(
            width: 40,
            height: double.infinity,
            child: Icon(
              active ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: active
                  ? TransportBarTheme.accentPlay
                  : TransportBarTheme.textPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
