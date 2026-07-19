part of 'mixer_view.dart';

/// Horizontal pan — pointer-driven so the mixer [ListView] cannot steal drags.
/// Double-tap resets to center (0.5).
class _MixerPanSlider extends StatefulWidget {
  const _MixerPanSlider({
    super.key,
    required this.pan,
    required this.accent,
    required this.onChanged,
  });

  final double pan;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  State<_MixerPanSlider> createState() => _MixerPanSliderState();
}

class _MixerPanSliderState extends State<_MixerPanSlider> {
  double? _dragPan;
  ScrollHoldController? _scrollHold;
  int? _activePointer;
  Offset? _downGlobal;
  bool _dragging = false;
  bool _suppressUntilUp = false;
  final GlobalKey _trackKey = GlobalKey();
  DateTime? _lastTapAt;
  Offset? _lastTapPos;

  static const _doubleTapSlop = 40.0;
  static const _dragSlop = 8.0;
  static const _doubleTapTimeout = Duration(milliseconds: 500);

  double get _displayPan => (_dragPan ?? widget.pan).clamp(0.0, 1.0);

  void _setFromGlobal(Offset global) {
    final box = _trackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final localX = box.globalToLocal(global).dx;
    final pad = MixerTheme.panCapWidth;
    final usable = math.max(1.0, box.size.width - pad);
    final t = ((localX - pad / 2) / usable).clamp(0.0, 1.0);
    setState(() => _dragPan = t);
    widget.onChanged(t);
  }

  void _beginHold() {
    _scrollHold?.cancel();
    _scrollHold = Scrollable.maybeOf(context)?.position.hold(() {});
  }

  void _endHold() {
    _scrollHold?.cancel();
    _scrollHold = null;
    _activePointer = null;
    _downGlobal = null;
    _dragging = false;
    _suppressUntilUp = false;
    if (_dragPan != null) setState(() => _dragPan = null);
  }

  bool _isDoubleTap(Offset global) {
    final now = DateTime.now();
    final lastAt = _lastTapAt;
    final lastPos = _lastTapPos;
    _lastTapAt = now;
    _lastTapPos = global;
    if (lastAt == null || lastPos == null) return false;
    if (now.difference(lastAt) > _doubleTapTimeout) return false;
    return (global - lastPos).distance <= _doubleTapSlop;
  }

  void _resetToCenter() {
    setState(() => _dragPan = null);
    widget.onChanged(0.5);
    _lastTapAt = null;
    _lastTapPos = null;
    _suppressUntilUp = true;
    _dragging = false;
  }

  @override
  void dispose() {
    _scrollHold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MixerTheme.panRowHeight,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'L',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MixerTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) {
                      if (_activePointer != null) return;
                      _activePointer = e.pointer;
                      _downGlobal = e.position;
                      _dragging = false;
                      _suppressUntilUp = false;
                      _beginHold();
                      if (_isDoubleTap(e.position)) {
                        _resetToCenter();
                      }
                    },
                    onPointerMove: (e) {
                      if (e.pointer != _activePointer) return;
                      if (_suppressUntilUp) return;
                      final down = _downGlobal;
                      if (down == null) return;
                      if (!_dragging) {
                        if ((e.position - down).distance < _dragSlop) return;
                        _dragging = true;
                        // Drag started — this press is not a tap.
                        _lastTapAt = null;
                        _lastTapPos = null;
                      }
                      if (_scrollHold == null) _beginHold();
                      _setFromGlobal(e.position);
                    },
                    onPointerUp: (e) {
                      if (e.pointer != _activePointer) return;
                      if (!_suppressUntilUp && !_dragging) {
                        // Single tap: jump to touch point.
                        _setFromGlobal(e.position);
                      }
                      _endHold();
                    },
                    onPointerCancel: (e) {
                      if (e.pointer != _activePointer) return;
                      _endHold();
                    },
                    child: CustomPaint(
                      key: _trackKey,
                      painter: _MixerPanPainter(
                        pan: _displayPan,
                        accent: widget.accent,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'R',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MixerTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _panLabel(_displayPan),
            style: TextStyle(
              fontSize: MixerTheme.readoutFontSize,
              fontWeight: FontWeight.w600,
              color: MixerTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MixerPanPainter extends CustomPainter {
  _MixerPanPainter({required this.pan, required this.accent});

  final double pan;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final capW = MixerTheme.panCapWidth;
    final left = capW / 2;
    final right = size.width - capW / 2;
    final railW = right - left;
    if (railW <= 0) return;

    final well = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, cy),
        width: railW + 6,
        height: MixerTheme.panWellHeight,
      ),
      const Radius.circular(5),
    );
    paintEngravedWell(canvas, well);

    final midX = size.width / 2;
    canvas.drawLine(
      Offset(midX, cy - MixerTheme.panWellHeight * 0.28),
      Offset(midX, cy + MixerTheme.panWellHeight * 0.28),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    final panX = left + railW * pan.clamp(0.0, 1.0);
    final fillLeft = math.min(midX, panX);
    final fillRight = math.max(midX, panX);
    if ((fillRight - fillLeft).abs() > 0.5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            fillLeft,
            cy - MixerTheme.panRailHeight / 2,
            fillRight,
            cy + MixerTheme.panRailHeight / 2,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = accent.withValues(alpha: 0.9),
      );
    }

    paintFaderCap(
      canvas,
      cap: RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(panX, cy),
          width: MixerTheme.panCapWidth,
          height: MixerTheme.panCapHeight,
        ),
        const Radius.circular(3),
      ),
      accent: accent,
      horizontalTick: false,
    );
  }

  @override
  bool shouldRepaint(covariant _MixerPanPainter oldDelegate) =>
      oldDelegate.pan != pan || oldDelegate.accent != accent;
}
