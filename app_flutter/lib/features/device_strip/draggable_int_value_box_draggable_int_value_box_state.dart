part of 'draggable_int_value_box.dart';

class _DraggableIntValueBoxState extends State<DraggableIntValueBox> {
  double _dragStartY = 0;
  int _dragStartValue = 0;

  @override
  Widget build(BuildContext context) {
    final display = widget.value >= 0 ? '+${widget.value}' : '${widget.value}';
    final muted = widget.accentColor.withValues(alpha: 0.55);

    void bump(int delta) {
      final next = (widget.value + delta).clamp(widget.min, widget.max);
      if (next != widget.value) widget.onChanged(next);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: widget.controlSize + 4,
          decoration: BoxDecoration(
            color: const Color(0xFF14141C),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: _StepButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  color: muted,
                  onTap: () => bump(1),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (d) {
                  _dragStartY = d.localPosition.dy;
                  _dragStartValue = widget.value;
                },
                onVerticalDragUpdate: (d) {
                  final delta =
                      ((_dragStartY - d.localPosition.dy) / 8).round();
                  final next =
                      (_dragStartValue + delta).clamp(widget.min, widget.max);
                  if (next != widget.value) widget.onChanged(next);
                },
                onDoubleTap: () => widget.onChanged(0),
                child: Text(
                  display,
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              Expanded(
                child: _StepButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  color: muted,
                  onTap: () => bump(-1),
                ),
              ),
            ],
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 3),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: widget.controlSize >= 56 ? 10 : 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
