part of 'clip_renderer.dart';

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
                  color: ArrangementClipTheme.highlightShadow
                      .withValues(alpha: 0.45),
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
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
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
    if (renderer.clipBackgroundColor ==
        ArrangementClipTheme.sampleClipBackground) {
      return ArrangementClipTheme.sampleClipBorder;
    }
    if (renderer.clipBackgroundColor ==
        ArrangementClipTheme.automationClipBackground) {
      return ArrangementClipTheme.automationClipBorder;
    }
    if (renderer.clipBackgroundColor ==
        ArrangementClipTheme.freezeClipBackground) {
      return ArrangementClipTheme.freezeClipBorder;
    }
    return ArrangementClipTheme.midiClipBorder;
  }
}
