part of 'arrangement_view.dart';

class _ClipResizeHandleState extends State<_ClipResizeHandle> {
  bool _active = false;

  Color get _idleColor {
    switch (widget.clipKind) {
      case ClipContentKind.midi:
        return ArrangementClipTheme.resizeHandleMidiIdleColor;
      case ClipContentKind.sample:
        return ArrangementClipTheme.resizeHandleSampleIdleColor;
      case ClipContentKind.automation:
        return ArrangementClipTheme.resizeHandleAutomationIdleColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The handle brightens to full white on touch so the user sees the drag
    // has begun. Idle uses a dedicated solid bright color matching the
    // clip type's unique color scheme.
    final color =
        _active ? ArrangementClipTheme.resizeHandleActiveColor : _idleColor;
    return Semantics(
      label: 'Resize clip',
      child: SizedBox(
        width: kResizeHandleHitWidth,
        height: double.infinity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            setState(() => _active = true);
            widget.onResizeStart(details);
          },
          onHorizontalDragUpdate: widget.onResizeUpdate,
          onHorizontalDragEnd: (details) {
            setState(() => _active = false);
            widget.onResizeEnd(details);
          },
          onHorizontalDragCancel: () {
            setState(() => _active = false);
            widget.onResizeCancel();
          },
          // AlignRight: the 12 px visual bar pins to the right edge of the
          // 28 px hit zone so the bar lands flush on the clip's right edge
          // regardless of hit-zone padding.
          //
          // The square side faces the clip content (so the bar reads as
          // attached to the clip) and the rounded side faces outward —
          // mirrors the right-boundary handle of the sampler trim control.
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: kResizeHandleVisualWidth,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
                border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.drag_handle,
                  size: 12,
                  color: Color(0x8C000000), // black @ 0.55
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
