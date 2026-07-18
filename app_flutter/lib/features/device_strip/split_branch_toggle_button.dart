import 'package:flutter/material.dart';

/// Scaled-up clone of the synth Note FX / FX chrome toggle
/// (`_FxToggleButton`): dark body + accent top bracket + side triangle.
class SplitBranchToggleButton extends StatelessWidget {
  const SplitBranchToggleButton({
    super.key,
    required this.label,
    required this.active,
    required this.accentColor,
    required this.onPressed,
  });

  /// ~1.5× the chrome FX toggle (53×25).
  static const double width = 80;
  static const double height = 38;
  static const double _bodyWidth = 60;
  static const double _fontSize = 12;

  final String label;
  final bool active;
  final Color accentColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: _bodyWidth,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF222229),
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFF2F2F2),
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SplitFxAdornmentPainter(
                    accentColor: accentColor,
                    active: active,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same geometry as `_FxButtonAdornmentPainter`, scaled to [SplitBranchToggleButton].
class _SplitFxAdornmentPainter extends CustomPainter {
  const _SplitFxAdornmentPainter({
    required this.accentColor,
    required this.active,
  });

  final Color accentColor;
  final bool active;

  // Chrome reference: body 40 wide, bracket height 3, triangle at x 42.5–47.5.
  static const double _scale = SplitBranchToggleButton._bodyWidth / 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyW = SplitBranchToggleButton._bodyWidth;
    final bracketH = 3.0 * _scale;

    final bracketPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final bracket = Path()
      ..moveTo(0, bracketH)
      ..lineTo(0, 0)
      ..lineTo(bodyW, 0)
      ..lineTo(bodyW, bracketH);
    canvas.drawPath(bracket, bracketPaint);

    final tipX = 47.5 * _scale;
    final baseX = 42.5 * _scale;
    final midY = size.height * 0.5;
    final halfH = 4.0 * _scale;
    final triangle = Path()
      ..moveTo(tipX, midY)
      ..lineTo(baseX, midY - halfH)
      ..lineTo(baseX, midY + halfH)
      ..close();
    canvas.drawPath(
      triangle,
      Paint()
        ..color = const Color(0xFFF2F2F2)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_SplitFxAdornmentPainter old) =>
      old.accentColor != accentColor || old.active != active;
}
