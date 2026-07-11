part of 'sample_library_screen.dart';

class WaveformPainter extends CustomPainter {
  const WaveformPainter({
    required this.peaks,
    this.color = const Color(0xFF7EB6FF),
    this.durationSec,
    this.trimStartSec,
    this.trimEndSec,
    this.dimOutsideTrim = false,
    this.outsideTrimOpacity = 0.35,
  });

  final List<double> peaks;
  final Color color;

  /// When set with [dimOutsideTrim], peak X positions follow sample time.
  final double? durationSec;
  final double? trimStartSec;
  final double? trimEndSec;
  final bool dimOutsideTrim;
  final double outsideTrimOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) {
      return;
    }
    final midY = size.height / 2;
    final useTimeline =
        dimOutsideTrim && durationSec != null && durationSec! > 0;
    final dur = useTimeline ? durationSec! : 1.0;
    final trimStart = trimStartSec ?? 0.0;
    final trimEnd = trimEndSec != null && trimEndSec! > 0 ? trimEndSec! : dur;

    final paint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    if (!useTimeline) {
      paint.color = color;
      final step = size.width / peaks.length;
      for (var i = 0; i < peaks.length; i++) {
        final peak = peaks[i].clamp(0.0, 1.0);
        final x = i * step + step / 2;
        final half = peak * midY;
        canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), paint);
      }
      return;
    }

    for (var i = 0; i < peaks.length; i++) {
      final peak = peaks[i].clamp(0.0, 1.0);
      final timeSec = (i + 0.5) / peaks.length * dur;
      final x = timeSec / dur * size.width;
      final inTrim = timeSec >= trimStart && timeSec <= trimEnd;
      paint.color = color.withValues(alpha: inTrim ? 1.0 : outsideTrimOpacity);
      final half = peak * midY;
      canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks ||
        oldDelegate.color != color ||
        oldDelegate.durationSec != durationSec ||
        oldDelegate.trimStartSec != trimStartSec ||
        oldDelegate.trimEndSec != trimEndSec ||
        oldDelegate.dimOutsideTrim != dimOutsideTrim ||
        oldDelegate.outsideTrimOpacity != outsideTrimOpacity;
  }
}
