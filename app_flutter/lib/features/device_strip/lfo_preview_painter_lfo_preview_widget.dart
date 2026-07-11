part of 'lfo_preview_painter.dart';

class LfoPreviewWidget extends StatelessWidget {
  const LfoPreviewWidget({
    super.key,
    required this.morph,
    required this.spread,
    required this.onChanged,
    this.polarity = 0,
    this.analogMode = 0,
  });

  final double morph;
  final double spread;
  final int polarity;
  final int analogMode;
  final void Function(String param, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE8A54B);
    final isAnalog = analogMode != 0;
    final isBipolar = polarity == 0;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: LfoPreviewPainter(
              morph: morph,
              spread: spread,
              polarity: polarity,
              analogMode: analogMode,
            ),
            size: Size.infinite,
          ),
        ),
        // Top-right: DG/AN + Polarity toggle buttons
        Positioned(
          top: 4,
          right: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Polarity toggle (± / +)
              GestureDetector(
                onTap: () => onChanged('polarity', isBipolar ? 1.0 : 0.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isBipolar
                        ? Colors.white.withValues(alpha: 0.08)
                        : accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isBipolar ? Colors.white24 : accent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isBipolar ? '±' : '+',
                    style: TextStyle(
                      color: isBipolar ? Colors.white54 : accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              // DG/AN toggle
              GestureDetector(
                onTap: () => onChanged('analogMode', isAnalog ? 0.0 : 1.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAnalog
                        ? accent.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isAnalog ? accent : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isAnalog ? 'AN' : 'DG',
                    style: TextStyle(
                      color: isAnalog ? accent : Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
