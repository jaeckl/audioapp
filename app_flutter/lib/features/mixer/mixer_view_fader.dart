part of 'mixer_view.dart';

/// Vertical gain fader — engraved well + raised cap.
/// Double-tap resets to unity (1.0).
class _MixerFader extends StatefulWidget {
  const _MixerFader({
    super.key,
    required this.gain,
    required this.accent,
    required this.onChanged,
    this.meter,
  });

  final double gain;
  final Color accent;
  final ValueChanged<double> onChanged;
  final DeviceMeterReading? meter;

  @override
  State<_MixerFader> createState() => _MixerFaderState();
}

class _MixerFaderState extends State<_MixerFader> {
  double? _dragGain;
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

  double get _displayGain => (_dragGain ?? widget.gain).clamp(0.0, 1.0);

  void _setFromGlobal(Offset global, double height) {
    final box = _trackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final localY = box.globalToLocal(global).dy;
    final pad = MixerTheme.faderCapHeight;
    final usable = math.max(1.0, height - pad);
    final t = 1.0 - ((localY - pad / 2) / usable).clamp(0.0, 1.0);
    setState(() => _dragGain = t);
    widget.onChanged(t);
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

  void _resetToUnity() {
    setState(() => _dragGain = null);
    widget.onChanged(1.0);
    _lastTapAt = null;
    _lastTapPos = null;
    _suppressUntilUp = true;
    _dragging = false;
  }

  void _endPointer() {
    _activePointer = null;
    _downGlobal = null;
    _dragging = false;
    _suppressUntilUp = false;
    if (_dragGain != null) setState(() => _dragGain = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StereoMeter(
                left: widget.meter?.leftLevel ?? 0,
                right: widget.meter?.rightLevel ?? 0,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: MixerTheme.faderHitWidth,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;
                    return Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) {
                        if (_activePointer != null) return;
                        _activePointer = e.pointer;
                        _downGlobal = e.position;
                        _dragging = false;
                        _suppressUntilUp = false;
                        if (_isDoubleTap(e.position)) {
                          _resetToUnity();
                        }
                      },
                      onPointerMove: (e) {
                        if (e.pointer != _activePointer) return;
                        if (_suppressUntilUp) return;
                        final down = _downGlobal;
                        if (down == null) return;
                        if (!_dragging) {
                          if ((e.position - down).distance < _dragSlop) {
                            return;
                          }
                          _dragging = true;
                          _lastTapAt = null;
                          _lastTapPos = null;
                        }
                        _setFromGlobal(e.position, height);
                      },
                      onPointerUp: (e) {
                        if (e.pointer != _activePointer) return;
                        if (!_suppressUntilUp && !_dragging) {
                          _setFromGlobal(e.position, height);
                        }
                        _endPointer();
                      },
                      onPointerCancel: (e) {
                        if (e.pointer != _activePointer) return;
                        _endPointer();
                      },
                      child: CustomPaint(
                        key: _trackKey,
                        painter: _MixerFaderPainter(
                          gain: _displayGain,
                          accent: widget.accent,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          MixerTheme.gainLabel(_displayGain),
          style: TextStyle(
            fontSize: MixerTheme.readoutFontSize,
            fontWeight: FontWeight.w600,
            color: MixerTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MixerFaderPainter extends CustomPainter {
  _MixerFaderPainter({required this.gain, required this.accent});

  final double gain;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final capH = MixerTheme.faderCapHeight;
    final capW = MixerTheme.faderCapWidth;
    final top = capH / 2;
    final bottom = size.height - capH / 2;
    final railHeight = bottom - top;
    if (railHeight <= 0) return;

    final well = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, size.height / 2),
        width: MixerTheme.faderWellWidth,
        height: railHeight + 4,
      ),
      const Radius.circular(4),
    );
    paintEngravedWell(canvas, well);

    final railW = MixerTheme.faderRailWidth;
    final filledH = railHeight * gain.clamp(0.0, 1.0);
    if (filledH > 0.5) {
      final fillTop = bottom - filledH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - railW / 2, fillTop, railW, filledH),
          const Radius.circular(2),
        ),
        Paint()..color = accent.withValues(alpha: 0.9),
      );
    }

    final capY = bottom - railHeight * gain.clamp(0.0, 1.0);
    paintFaderCap(
      canvas,
      cap: RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, capY),
          width: capW,
          height: capH,
        ),
        const Radius.circular(3),
      ),
      accent: accent,
      horizontalTick: true,
    );
  }

  @override
  bool shouldRepaint(covariant _MixerFaderPainter oldDelegate) =>
      oldDelegate.gain != gain || oldDelegate.accent != accent;
}
