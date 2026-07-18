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
    final color =
        _active ? ArrangementClipTheme.resizeHandleActiveColor : _idleColor;
    final typeLabel = switch (widget.clipKind) {
      ClipContentKind.midi => 'MIDI',
      ClipContentKind.sample => 'audio',
      ClipContentKind.automation => 'automation',
    };
    return Semantics(
      label: 'Resize clip',
      value: '$typeLabel clip',
      hint: 'Drag horizontally to change the clip length',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: SizedBox(
          width: widget.hitWidth,
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
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedContainer(
                key: const ValueKey('clip-resize-rail'),
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                width: kResizeHandleVisualWidth,
                height: _active ? 32 : 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _active ? 1 : 0.72),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(3),
                  ),
                  boxShadow: _active
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 5,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
