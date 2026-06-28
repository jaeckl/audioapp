import 'package:flutter/material.dart';

import 'transport_bar_theme.dart';

/// Compact BPM readout — drag the number up/down to change tempo.
class TransportBpmBox extends StatefulWidget {
  const TransportBpmBox({
    super.key,
    required this.bpm,
    this.enabled = true,
    this.onChanged,
  });

  static const int minBpm = 40;
  static const int maxBpm = 300;
  static const double dragPixelsPerStep = 10;

  final int bpm;
  final bool enabled;
  final ValueChanged<int>? onChanged;

  @override
  State<TransportBpmBox> createState() => _TransportBpmBoxState();
}

class _TransportBpmBoxState extends State<TransportBpmBox> {
  double _dragStartY = 0;
  int _dragStartBpm = 0;

  void _onDragStart(DragStartDetails details) {
    _dragStartY = details.localPosition.dy;
    _dragStartBpm = widget.bpm;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || widget.onChanged == null) return;
    final delta =
        ((_dragStartY - details.localPosition.dy) / TransportBpmBox.dragPixelsPerStep)
            .round();
    final next =
        (_dragStartBpm + delta).clamp(TransportBpmBox.minBpm, TransportBpmBox.maxBpm);
    if (next != widget.bpm) {
      widget.onChanged!(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TransportBarTheme.textMuted,
          fontSize: 9,
          letterSpacing: 0.6,
          height: 1,
        );
    final valueStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: TransportBarTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          height: 1.1,
        );

    return SizedBox(
      width: TransportBarTheme.bpmBoxWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TransportBarTheme.chipFill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TransportBarTheme.cardInnerPaddingH,
            vertical: TransportBarTheme.cardInnerPaddingV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('BPM', style: labelStyle),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: widget.enabled ? _onDragStart : null,
                  onVerticalDragUpdate: widget.enabled ? _onDragUpdate : null,
                  child: Center(
                    child: Text(
                      '${widget.bpm}',
                      textAlign: TextAlign.center,
                      style: valueStyle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
