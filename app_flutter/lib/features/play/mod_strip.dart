import 'package:flutter/material.dart';

import 'play_deck_theme.dart';

/// Visual-only readout for live modulation and pitch bend.
///
/// Mod and bend are no longer dragged from a strip — the user drags
/// horizontally / vertically while holding a key or pad (see
/// `PlayKeyboard` and `MpcPadGrid`). This widget only mirrors the
/// current values so the musician can see what they're doing.
class ModStrip extends StatelessWidget {
  const ModStrip({
    super.key,
    required this.modulation,
    required this.pitchBend,
  });

  final double modulation;
  final double pitchBend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: ColoredBox(
        color: PlayDeckTheme.stripBackground,
        child: Row(
          children: [
            const SizedBox(width: 8),
            const _Label('MOD'),
            const SizedBox(width: 4),
            _Readout(
              value: modulation,
              color: const Color(0xFF7AB8E0),
            ),
            const SizedBox(width: 16),
            const _Label('BEND'),
            const SizedBox(width: 4),
            _Readout(
              value: pitchBend,
              color: const Color(0xFFE87B8A),
              center: true,
            ),
            const Spacer(),
            const _Hint('drag on a key'),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 9, color: PlayDeckTheme.railLabel),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        color: PlayDeckTheme.railLabel,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.value,
    required this.color,
    this.center = false,
  });

  final double value;
  final Color color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 8,
      child: CustomPaint(painter: _ReadoutPainter(value, color, center)),
    );
  }
}

class _ReadoutPainter extends CustomPainter {
  _ReadoutPainter(this.value, this.color, this.center);
  final double value;
  final Color color;
  final bool center;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = const Color(0xFF2A2A30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
      track,
    );
    if (center) {
      final midX = size.width / 2;
      canvas.drawLine(
        Offset(midX, 0),
        Offset(midX, size.height),
        Paint()..color = const Color(0xFF3A3A44),
      );
    }
    final clamped = value.clamp(center ? -1.0 : 0.0, 1.0);
    final fillPaint = Paint()..color = color.withValues(alpha: 0.85);
    if (center) {
      final midX = size.width / 2;
      final width = (clamped.abs() * (size.width / 2));
      final left = clamped >= 0 ? midX : midX - width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, width, size.height),
          const Radius.circular(2),
        ),
        fillPaint,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, clamped * size.width, size.height),
          const Radius.circular(2),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReadoutPainter old) =>
      old.value != value || old.color != color || old.center != center;
}
