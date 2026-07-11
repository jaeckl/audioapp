part of 'device_strip_chrome_panels.dart';

class _DynamicsSideColumn extends StatelessWidget {
  const _DynamicsSideColumn({
    required this.label,
    required this.meterLevel,
    required this.accentColor,
    required this.bottomKnob,
  });

  static const double _meterWidth = 28;

  final String label;
  final double meterLevel;
  final Color accentColor;
  final Widget bottomKnob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleLevel =
        meterLevel <= 0.001 ? 0.0 : meterLevel.clamp(0.05, 1.0);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white38,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: SizedBox(
              width: _meterWidth,
              child: ColoredBox(
                color: Colors.black26,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: visibleLevel,
                    widthFactor: 1.0,
                    child:
                        ColoredBox(color: accentColor.withValues(alpha: 0.65)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        bottomKnob,
      ],
    );
  }
}
