import 'package:flutter/material.dart';

/// Compact integer readout — drag vertically to change value.
class DraggableIntValueBox extends StatefulWidget {
  const DraggableIntValueBox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.min = -2,
    this.max = 2,
    this.label = 'Oct',
    this.showLabel = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final Color accentColor;
  final int min;
  final int max;
  final String label;
  final bool showLabel;

  @override
  State<DraggableIntValueBox> createState() => _DraggableIntValueBoxState();
}

class _DraggableIntValueBoxState extends State<DraggableIntValueBox> {
  double _dragStartY = 0;
  int _dragStartValue = 0;

  @override
  Widget build(BuildContext context) {
    final display = widget.value >= 0 ? '+${widget.value}' : '${widget.value}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) {
            _dragStartY = d.localPosition.dy;
            _dragStartValue = widget.value;
          },
          onVerticalDragUpdate: (d) {
            final delta = ((_dragStartY - d.localPosition.dy) / 12).round();
            final next = (_dragStartValue + delta).clamp(widget.min, widget.max);
            if (next != widget.value) {
              widget.onChanged(next);
            }
          },
          onDoubleTap: () => widget.onChanged(0),
          child: Container(
            width: 44,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF14141C),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: widget.accentColor.withValues(alpha: 0.45)),
            ),
            child: Text(
              display,
              style: TextStyle(
                color: widget.accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

int subtractiveOctaveFromNorm(double norm) => ((norm - 0.5) * 4).round().clamp(-2, 2);

double subtractiveNormFromOctave(int octave) => (octave / 4.0) + 0.5;
