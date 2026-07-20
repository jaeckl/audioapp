part of 'time_fx_panels.dart';

/// LFO waveform button group — Filter-style underline cells in the plate.
class _PhaserWaveformRow extends StatelessWidget {
  const _PhaserWaveformRow({
    required this.selectedIndex,
    required this.onSelected,
    required this.accent,
    required this.modulated,
    required this.automated,
    required this.modulationAmount,
    required this.connectModeActive,
    required this.linkModeActive,
    this.onModulationAssign,
    this.onLinkTap,
    this.onAutomateRequest,
  });

  static const labels = ['SIN', 'TRI', 'RMP', 'RND'];

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accent;
  final bool modulated;
  final bool automated;
  final double modulationAmount;
  final bool connectModeActive;
  final bool linkModeActive;
  final ValueChanged<double>? onModulationAssign;
  final VoidCallback? onLinkTap;
  final VoidCallback? onAutomateRequest;

  @override
  Widget build(BuildContext context) {
    const height = DevicePanelTheme.modeRowHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 200.0;
        return HorizontalGroupShell(
          key: const ValueKey('phaser-waveform-selector'),
          width: width,
          height: height,
          value: selectedIndex.toDouble().clamp(0, 3),
          maxValue: 3,
          accent: accent,
          flat: true,
          modulationActive: modulated,
          modulationAmount: modulationAmount,
          automationActive: automated,
          connectModeActive: connectModeActive,
          linkModeActive: linkModeActive,
          onModulationAssign: onModulationAssign,
          onLinkTap: onLinkTap,
          onAutomateRequest: onAutomateRequest,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _PhaserWaveformCell(
                    label: labels[i],
                    waveIndex: i,
                    selected: selectedIndex == i,
                    accent: accent,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PhaserWaveformCell extends StatelessWidget {
  const _PhaserWaveformCell({
    required this.label,
    required this.waveIndex,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final int waveIndex;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : Colors.white.withValues(alpha: 0.46);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(22, 10),
                painter: _PhaserWaveformIconPainter(
                  waveIndex: waveIndex,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          if (selected)
            Align(
              alignment: Alignment.bottomCenter,
              child: ColoredBox(color: accent, child: const SizedBox(height: 2)),
            ),
        ],
      ),
    );
  }
}

class _PhaserWaveformIconPainter extends CustomPainter {
  const _PhaserWaveformIconPainter({
    required this.waveIndex,
    required this.color,
  });

  final int waveIndex;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final mid = size.height / 2;
    switch (waveIndex) {
      case 0: // sine
        path.moveTo(0, mid);
        path.cubicTo(
          size.width * 0.25,
          -mid * 0.2,
          size.width * 0.25,
          size.height + mid * 0.2,
          size.width * 0.5,
          mid,
        );
        path.cubicTo(
          size.width * 0.75,
          -mid * 0.2,
          size.width * 0.75,
          size.height + mid * 0.2,
          size.width,
          mid,
        );
      case 1: // triangle
        path.moveTo(0, size.height);
        path.lineTo(size.width * 0.25, 0);
        path.lineTo(size.width * 0.75, size.height);
        path.lineTo(size.width, 0);
      case 2: // ramp
        path.moveTo(0, size.height);
        path.lineTo(size.width * 0.85, 0);
        path.lineTo(size.width * 0.85, size.height);
        path.lineTo(size.width, 0);
      default: // random steps
        path.moveTo(0, mid);
        path.lineTo(size.width * 0.2, mid * 0.3);
        path.lineTo(size.width * 0.2, size.height * 0.85);
        path.lineTo(size.width * 0.45, size.height * 0.85);
        path.lineTo(size.width * 0.45, mid * 0.4);
        path.lineTo(size.width * 0.7, mid * 0.4);
        path.lineTo(size.width * 0.7, size.height * 0.75);
        path.lineTo(size.width, size.height * 0.75);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PhaserWaveformIconPainter oldDelegate) =>
      oldDelegate.waveIndex != waveIndex || oldDelegate.color != color;
}
