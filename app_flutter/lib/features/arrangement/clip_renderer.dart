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

  @override
  bool shouldRepaint(covariant _ClipContentPainter oldDelegate) {
    return oldDelegate.renderer != renderer;
  }
}
