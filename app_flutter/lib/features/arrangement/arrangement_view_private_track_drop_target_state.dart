part of 'arrangement_view.dart';

class _TrackDropTargetState extends State<_TrackDropTarget> {
  final GlobalKey _targetKey = GlobalKey();
  _TrackDropIntent? _intent;

  _TrackDropIntent? _intentFor(DragTargetDetails<_TrackDragData> details) {
    final box = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(details.offset);
    final fraction = (local.dy / box.size.height).clamp(0.0, 1.0);
    final sourceIsGroup = details.data.track.isGroup;
    final zone = widget.target.isGroup &&
            !sourceIsGroup &&
            fraction >= 0.25 &&
            fraction <= 0.75
        ? _TrackDropZone.inside
        : fraction < 0.5
            ? _TrackDropZone.before
            : _TrackDropZone.after;
    return widget.intentBuilder(details.data, widget.target, zone);
  }

  void _updateIntent(DragTargetDetails<_TrackDragData> details) {
    final next = _intentFor(details);
    if (next == _intent) return;
    setState(() => _intent = next);
  }

  @override
  Widget build(BuildContext context) {
    final intent = _intent;
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      key: _targetKey,
      child: DragTarget<_TrackDragData>(
        onWillAcceptWithDetails: (details) {
          final next = _intentFor(details);
          if (next == null) return false;
          setState(() => _intent = next);
          return true;
        },
        onMove: _updateIntent,
        onLeave: (_) {
          if (_intent != null) setState(() => _intent = null);
        },
        onAcceptWithDetails: (details) {
          final accepted = _intentFor(details) ?? _intent;
          setState(() => _intent = null);
          if (accepted != null) unawaited(widget.onDrop(accepted));
        },
        builder: (context, candidateData, rejectedData) => Stack(
          children: [
            widget.child,
            if (intent?.zone == _TrackDropZone.inside)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      border: Border.all(color: accent, width: 2),
                    ),
                  ),
                ),
              ),
            if (intent?.zone == _TrackDropZone.before ||
                intent?.zone == _TrackDropZone.after)
              Positioned(
                left: 0,
                right: 0,
                top: intent?.zone == _TrackDropZone.before ? 0 : null,
                bottom: intent?.zone == _TrackDropZone.after ? 0 : null,
                child: IgnorePointer(
                  child: Container(height: 3, color: accent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
