part of 'spectral_loud_split_panel.dart';

/// Live log-Hz / dB spectrum with two horizontal threshold handles.
class SpectralLoudPreview extends StatefulWidget {
  const SpectralLoudPreview({
    super.key,
    required this.spectrum,
    required this.highDb,
    required this.lowDb,
    required this.accent,
    required this.onHighDb,
    required this.onLowDb,
  });

  final List<double> spectrum;
  final double highDb;
  final double lowDb;
  final Color accent;
  final ValueChanged<double> onHighDb;
  final ValueChanged<double> onLowDb;

  static const double minDb = -80;
  static const double maxDb = 0;
  static const double hitRadius = 50;

  @override
  State<SpectralLoudPreview> createState() => _SpectralLoudPreviewState();
}

class _SpectralLoudPreviewState extends State<SpectralLoudPreview> {
  int? _drag; // 0=high, 1=low

  static double dbToY(double db, double height) {
    final t = ((db - SpectralLoudPreview.minDb) /
            (SpectralLoudPreview.maxDb - SpectralLoudPreview.minDb))
        .clamp(0.0, 1.0);
    return (1.0 - t) * height;
  }

  static double yToDb(double y, double height) {
    if (height <= 0) return SpectralLoudPreview.minDb;
    final t = (1.0 - (y / height)).clamp(0.0, 1.0);
    return SpectralLoudPreview.minDb +
        t * (SpectralLoudPreview.maxDb - SpectralLoudPreview.minDb);
  }

  int? _nearest(double y, double h) {
    final highY = dbToY(widget.highDb, h);
    final lowY = dbToY(widget.lowDb, h);
    final dHigh = (y - highY).abs();
    final dLow = (y - lowY).abs();
    final r = SpectralLoudPreview.hitRadius;
    if (dHigh <= r && dHigh <= dLow) return 0;
    if (dLow <= r) return 1;
    return null;
  }

  void _apply(int which, double y, double h) {
    var db = yToDb(y, h);
    if (which == 0) {
      db = db.clamp(widget.lowDb + 6, SpectralLoudPreview.maxDb);
      widget.onHighDb(db);
    } else {
      db = db.clamp(SpectralLoudPreview.minDb, widget.highDb - 6);
      widget.onLowDb(db);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _SpectralLoudPainter(
                  spectrum: widget.spectrum,
                  highDb: widget.highDb,
                  lowDb: widget.lowDb,
                  accent: widget.accent,
                  dragIndex: _drag,
                ),
              ),
              Positioned.fill(
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: <Type, GestureRecognizerFactory>{
                    _EagerVerticalDragRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            _EagerVerticalDragRecognizer>(
                      () => _EagerVerticalDragRecognizer(
                        shouldClaim: (local) => _nearest(local.dy, h) != null,
                      ),
                      (instance) {
                        instance.onStart = (details) {
                          final i = _nearest(details.localPosition.dy, h);
                          if (i == null) return;
                          setState(() => _drag = i);
                          _apply(i, details.localPosition.dy, h);
                        };
                        instance.onUpdate = (details) {
                          final i = _drag;
                          if (i == null) return;
                          _apply(i, details.localPosition.dy, h);
                        };
                        instance.onEnd = (_) => setState(() => _drag = null);
                        instance.onCancel =
                            () => setState(() => _drag = null);
                      },
                    ),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EagerVerticalDragRecognizer extends VerticalDragGestureRecognizer {
  _EagerVerticalDragRecognizer({required this.shouldClaim});

  final bool Function(Offset localPosition) shouldClaim;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!shouldClaim(event.localPosition)) return;
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class _SpectralLoudPainter extends CustomPainter {
  const _SpectralLoudPainter({
    required this.spectrum,
    required this.highDb,
    required this.lowDb,
    required this.accent,
    required this.dragIndex,
  });

  final List<double> spectrum;
  final double highDb;
  final double lowDb;
  final Color accent;
  final int? dragIndex;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0E0E14),
    );

    final bins = spectrum.isEmpty ? List<double>.filled(24, 0.0) : spectrum;
    final barW = size.width / bins.length;
    for (var i = 0; i < bins.length; i++) {
      final level = bins[i].clamp(0.0, 1.0);
      final barH = level * size.height;
      canvas.drawRect(
        Rect.fromLTWH(i * barW, size.height - barH, barW - 1, barH),
        Paint()..color = accent.withValues(alpha: 0.35 + 0.45 * level),
      );
    }

    void drawThresh(double db, bool active) {
      final y = _SpectralLoudPreviewState.dbToY(db, size.height);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = active ? accent : accent.withValues(alpha: 0.75)
          ..strokeWidth = active ? 2 : 1.5,
      );
      canvas.drawCircle(
        Offset(size.width * 0.5, y),
        14,
        Paint()..color = accent.withValues(alpha: active ? 0.22 : 0.12),
      );
      canvas.drawCircle(Offset(size.width * 0.5, y), 6, Paint()..color = accent);
      canvas.drawCircle(
        Offset(size.width * 0.5, y),
        6,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final label = db >= -0.5 ? '0 dB' : '${db.round()} dB';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: accent,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(6, y - tp.height - 2));
    }

    drawThresh(highDb, dragIndex == 0);
    drawThresh(lowDb, dragIndex == 1);
  }

  @override
  bool shouldRepaint(covariant _SpectralLoudPainter old) =>
      old.highDb != highDb ||
      old.lowDb != lowDb ||
      old.accent != accent ||
      old.dragIndex != dragIndex ||
      old.spectrum.length != spectrum.length ||
      !_listEq(old.spectrum, spectrum);

  static bool _listEq(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
