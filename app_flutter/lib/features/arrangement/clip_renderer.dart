import 'package:flutter/material.dart';

import 'arrangement_clip_theme.dart';

/// Paints condensed clip content inside the arrangement timeline.
abstract class ClipRenderer {
  const ClipRenderer();

  Color get clipBackgroundColor;

  Color get clipContentBackgroundColor;

  /// Paints notes, waveform, or other condensed content inside [contentRect].
  void paintContent(Canvas canvas, Rect contentRect);

  /// Optional label row above the painted content (e.g. sample name).
  String? get headerLabel => null;

  /// Centered fallback when there is nothing to paint in the body.
  String? get emptyPlaceholder => null;

  /// When true, a small loop badge is painted on the clip chrome.
  bool get loopContentEnabled => false;

  /// Optional mode badge (e.g. COMP / EDIT on multi-take MIDI clips).
  String? get contentBadgeLabel => null;
}

/// Shared chrome + [ClipRenderer] body for arrangement clip blocks.
class ArrangementClipChrome extends StatelessWidget {
  const ArrangementClipChrome({
    super.key,
    required this.renderer,
    required this.highlighted,
    this.child,
  });

  final ClipRenderer renderer;
  final bool highlighted;
  final Widget? child;

  static const double _radius = 6;
  static const double _contentInset = 3;
  static const double _headerHeight = 18;

  /// Horizontal inset between clip border and beat-accurate content area.
  static const double contentInset = _contentInset;

  @override
  Widget build(BuildContext context) {
    final header = renderer.headerLabel;
    final placeholder = renderer.emptyPlaceholder;

    return Container(
      decoration: BoxDecoration(
        color: renderer.clipBackgroundColor,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: highlighted
              ? ArrangementClipTheme.highlightBorder
              : _idleBorderColor(renderer),
          width: highlighted ? 2 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: ArrangementClipTheme.highlightShadow.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(_contentInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            SizedBox(
              height: _headerHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  header,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CustomPaint(
                painter: _ClipContentPainter(renderer: renderer),
                child: placeholder == null
                    ? child
                    : Center(
                        child: Text(
                          placeholder,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: ArrangementClipTheme.placeholderLabel,
                              ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _idleBorderColor(ClipRenderer renderer) {
    if (renderer.clipBackgroundColor == ArrangementClipTheme.sampleClipBackground) {
      return ArrangementClipTheme.sampleClipBorder;
    }
    if (renderer.clipBackgroundColor == ArrangementClipTheme.automationClipBackground) {
      return ArrangementClipTheme.automationClipBorder;
    }
    if (renderer.clipBackgroundColor == ArrangementClipTheme.freezeClipBackground) {
      return ArrangementClipTheme.freezeClipBorder;
    }
    return ArrangementClipTheme.midiClipBorder;
  }
}

class _ClipContentPainter extends CustomPainter {
  const _ClipContentPainter({required this.renderer});

  final ClipRenderer renderer;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..color = renderer.clipContentBackgroundColor,
    );
    renderer.paintContent(canvas, rect);
    if (renderer.loopContentEnabled) {
      _paintLoopBadge(canvas, rect);
    }
    final badgeLabel = renderer.contentBadgeLabel;
    if (badgeLabel != null) {
      _paintModeBadge(canvas, rect, badgeLabel);
    }
  }

  void _paintLoopBadge(Canvas canvas, Rect rect) {
    const size = 10.0;
    final badgeRect = Rect.fromLTWH(
      rect.right - size - 2,
      rect.top + 2,
      size,
      size,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: '\u21BB',
        style: TextStyle(
          color: Color(0xCCFFFFFF),
          fontSize: 9,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + (badgeRect.width - textPainter.width) / 2,
        badgeRect.top + (badgeRect.height - textPainter.height) / 2,
      ),
    );
  }

  void _paintModeBadge(Canvas canvas, Rect rect, String label) {
    const height = 11.0;
    const hPad = 3.0;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xE6FFFFFF),
          fontSize: 7,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = textPainter.width + hPad * 2;
    final badgeRect = Rect.fromLTWH(rect.left + 2, rect.top + 2, width, height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(2)),
      Paint()..color = const Color(0x99000000),
    );
    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + hPad,
        badgeRect.top + (badgeRect.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ClipContentPainter oldDelegate) {
    return oldDelegate.renderer != renderer;
  }
}
