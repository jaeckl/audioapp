part of 'granular_device_panel.dart';

class _SampleRegionPreviewState extends State<_SampleRegionPreview> {
  _RegionDrag? _drag;

  _RegionDrag _target(double x, double width) {
    final start = widget.regionStart * width;
    final end = widget.regionEnd * width;
    if ((x - start).abs() <= 26) return _RegionDrag.start;
    if ((x - end).abs() <= 26) return _RegionDrag.end;
    return _RegionDrag.position;
  }

  void _update(double x, double width) {
    if (!widget.enabled || width <= 0) return;
    final value = (x / width).clamp(0.0, 1.0);
    switch (_drag ?? _RegionDrag.position) {
      case _RegionDrag.start:
        widget.onRegionStartChanged(value.clamp(0.0, widget.regionEnd - .02));
      case _RegionDrag.end:
        widget.onRegionEndChanged(value.clamp(widget.regionStart + .02, 1.0));
      case _RegionDrag.position:
        widget.onPositionChanged(
          value.clamp(widget.regionStart, widget.regionEnd),
        );
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled
              ? (details) {
                  _drag = _RegionDrag.position;
                  _update(details.localPosition.dx, constraints.maxWidth);
                  _drag = null;
                }
              : null,
          onPanStart: widget.enabled
              ? (details) {
                  setState(() => _drag =
                      _target(details.localPosition.dx, constraints.maxWidth));
                  _update(details.localPosition.dx, constraints.maxWidth);
                }
              : null,
          onPanUpdate: widget.enabled
              ? (details) =>
                  _update(details.localPosition.dx, constraints.maxWidth)
              : null,
          onPanEnd: (_) => setState(() => _drag = null),
          onPanCancel: () => setState(() => _drag = null),
          child: CustomPaint(
            painter: _SampleRegionPainter(
              peaks: widget.peaks,
              sampleName: widget.sampleName,
              regionStart: widget.regionStart,
              regionEnd: widget.regionEnd,
              position: widget.position,
              scan: widget.scan,
              activeHandle: _drag,
            ),
          ),
        ),
      );
}
