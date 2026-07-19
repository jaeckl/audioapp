part of 'device_chain_row.dart';

/// Accent bracket around a virtual sub-strip (top/bottom + corner ticks).
class _VirtualChainBracketPainter extends CustomPainter {
  const _VirtualChainBracketPainter(this.color);
  final Color color;

  /// Matches [DeviceChainLayout.virtualStripBracketStroke].
  static const strokeWidth = DeviceChainLayout.virtualStripBracketStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    const tick = 9.0;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset.zero, const Offset(0, tick), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, tick), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - tick), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - tick), paint);
  }

  @override
  bool shouldRepaint(covariant _VirtualChainBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Original bracket chrome: accent tint + corner-tick border + rotated title.
/// No vertical inset — nested devices keep the same height as top-level.
class _VirtualStripChrome extends StatelessWidget {
  const _VirtualStripChrome({
    required this.accent,
    required this.title,
    required this.children,
  });

  final Color accent;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: CustomPaint(
        painter: _VirtualChainBracketPainter(accent),
        child: ColoredBox(
          color: accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 0, 9, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: DeviceChainLayout.virtualStripTitleWidth,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: DeviceChainLayout.virtualStripTitleGap),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Strip-background pillar that visually cuts a parent bracket where a child
/// strip starts/ends. Bleeds past parent padding so top/bottom strokes vanish.
class _BracketCutPillar extends StatelessWidget {
  const _BracketCutPillar();

  static const _bleed = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight + _bleed * 2
            : 200.0;
        return SizedBox(
          width: DeviceChainLayout.virtualStripCutWidth,
          height: constraints.maxHeight,
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: DeviceChainLayout.virtualStripCutWidth,
            maxWidth: DeviceChainLayout.virtualStripCutWidth,
            minHeight: h,
            maxHeight: h,
            // Paint 1px right of layout slot so cut sits on bracket stroke.
            child: Transform.translate(
              offset: const Offset(1, 0),
              child: ColoredBox(
                color: DeviceStripTheme.stripBackground,
                child: SizedBox(
                  width: DeviceChainLayout.virtualStripCutWidth,
                  height: h,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Parent bracket looks interrupted: cut → child chrome → cut.
class _BracketInterruptedStrip extends StatelessWidget {
  const _BracketInterruptedStrip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BracketCutPillar(),
        child,
        const _BracketCutPillar(),
      ],
    );
  }
}
