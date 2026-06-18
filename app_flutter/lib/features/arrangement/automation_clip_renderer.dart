import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'arrangement_clip_theme.dart';
import 'clip_renderer.dart';

/// Condensed automation curve preview for arrangement clips.
class AutomationClipRenderer extends ClipRenderer {
  const AutomationClipRenderer(this.clip);

  final AutomationClipSnapshot clip;

  @override
  Color get clipBackgroundColor => ArrangementClipTheme.automationClipBackground;

  @override
  Color get clipContentBackgroundColor =>
      ArrangementClipTheme.contentBackground(clipBackgroundColor);

  @override
  String? get headerLabel => clip.isLinked ? clip.linkLabel : null;

  @override
  String? get emptyPlaceholder => clip.isLinked ? null : 'AUTO';

  @override
  void paintContent(Canvas canvas, Rect contentRect) {
    final points = clip.points;
    if (points.isEmpty || clip.lengthBeats <= 0) {
      return;
    }

    final inner = contentRect.deflate(2);
    if (inner.width <= 0 || inner.height <= 0) {
      return;
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = inner.left + (point.beat / clip.lengthBeats) * inner.width;
      final y = inner.bottom - point.value.clamp(0.0, 1.0) * inner.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final stroke = Paint()
      ..color = ArrangementClipTheme.automationCurve
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, stroke);

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ArrangementClipTheme.automationCurve.withValues(alpha: 0.28),
          ArrangementClipTheme.automationCurve.withValues(alpha: 0.02),
        ],
      ).createShader(inner);

    final fillPath = Path.from(path)
      ..lineTo(inner.right, inner.bottom)
      ..lineTo(inner.left, inner.bottom)
      ..close();
    canvas.drawPath(fillPath, fill);

    final dotPaint = Paint()..color = ArrangementClipTheme.automationCurve;
    for (final point in points) {
      final x = inner.left + (point.beat / clip.lengthBeats) * inner.width;
      final y = inner.bottom - point.value.clamp(0.0, 1.0) * inner.height;
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }
}

/// Floating chip to enter automation Link Mode (tap knob on device strip to assign).
class AutomationClipLinkChip extends StatelessWidget {
  const AutomationClipLinkChip({
    super.key,
    required this.label,
    required this.active,
    required this.linked,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool linked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = LibraryTheme.accentAutomation;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: 0.35)
                : linked
                    ? const Color(0xFF2A2238)
                    : const Color(0xFF1E1828),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? accent : accent.withValues(alpha: linked ? 0.55 : 0.85),
              width: active ? 1.5 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                linked ? Icons.link : Icons.link_off,
                size: 12,
                color: accent,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
