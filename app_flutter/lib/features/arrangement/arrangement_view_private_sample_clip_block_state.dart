part of 'arrangement_view.dart';

class _SampleClipBlockState extends State<_SampleClipBlock> {
  bool _started = false;

  void _ensureStarted(Offset globalPosition) {
    if (_started) return;
    _started = true;
    widget.onDragStart(globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LongPressDraggable<SampleClipDragData>(
        data: SampleClipDragData(
          clipId: widget.clip.id,
          sampleId: widget.clip.sampleId,
          sampleName: widget.clip.sampleName,
        ),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: SizedBox(
          width: 160,
          height: ArrangementTimelineMetrics.trackLaneHeight - 8,
          child: Material(
            color: Colors.transparent,
            child: ArrangementClipChrome(
              renderer: SampleClipRenderer(
                widget.clip,
                trackAccent: widget.trackAccent,
              ),
              highlighted: true,
            ),
          ),
        ),
        onDragUpdate: (details) {
          _ensureStarted(details.globalPosition);
          widget.onDragUpdate(details.globalPosition);
        },
        onDragEnd: (details) {
          if (!_started) return;
          _started = false;
          widget.onDragEnd(wasAccepted: details.wasAccepted);
        },
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: ArrangementClipChrome(
            renderer: SampleClipRenderer(
              widget.clip,
              trackAccent: widget.trackAccent,
            ),
            highlighted: true,
          ),
        ),
        child: GestureDetector(
          onTap: widget.highlighted ? null : widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          child: Opacity(
            opacity: widget.highlighted ? 0.35 : 1,
            child: ArrangementClipChrome(
              renderer: SampleClipRenderer(
                widget.clip,
                trackAccent: widget.trackAccent,
              ),
              highlighted: widget.highlighted || widget.selected,
            ),
          ),
        ),
      ),
    );
  }
}
