part of 'mixer_view.dart';

/// Classic segmented stereo VU — always visible trough + lit LEDs.
class _StereoMeter extends StatelessWidget {
  const _StereoMeter({required this.left, required this.right});

  final double left;
  final double right;

  static const int _segments = 16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MixerTheme.meterWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _VuStack(level: left)),
          const SizedBox(width: MixerTheme.meterBarGap),
          Expanded(child: _VuStack(level: right)),
        ],
      ),
    );
  }
}

class _VuStack extends StatelessWidget {
  const _VuStack({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final lit = (math.sqrt(level.clamp(0.0, 1.0)) * _StereoMeter._segments)
        .ceil()
        .clamp(0, _StereoMeter._segments);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MixerTheme.trough,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
        child: Column(
          children: [
            for (var i = _StereoMeter._segments - 1; i >= 0; i--) ...[
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i < lit
                        ? _segmentColor(i)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              if (i > 0) const SizedBox(height: 1),
            ],
          ],
        ),
      ),
    );
  }

  Color _segmentColor(int indexFromBottom) {
    final t = indexFromBottom / (_StereoMeter._segments - 1);
    if (t > 0.85) return const Color(0xFFFF5A5A);
    if (t > 0.65) return const Color(0xFFE8A54B);
    return const Color(0xFF65D68B);
  }
}
