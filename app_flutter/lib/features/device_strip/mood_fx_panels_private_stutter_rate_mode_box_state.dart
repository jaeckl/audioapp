part of 'mood_fx_panels.dart';

class _StutterRateModeBoxState extends State<_StutterRateModeBox> {
  double _dragStartValue = 0.0;
  double _dragStartY = 0.0;

  void _onDragStart(DragStartDetails details) {
    _dragStartValue = widget.rateMs;
    _dragStartY = details.localPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = (_dragStartY - details.localPosition.dy) * 8.0;
    widget.onRateMsChanged((_dragStartValue + delta).clamp(1.0, 5000.0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = Border.all(color: Colors.white.withValues(alpha: 0.10));
    return SizedBox(
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(7),
          border: border,
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StutterMiniToggle(
                      label: 'Sync',
                      active: widget.sync,
                      accent: widget.accent,
                      onTap: () => widget.onSyncChanged(true),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _StutterMiniToggle(
                      label: 'Ms',
                      active: !widget.sync,
                      accent: widget.accent,
                      onTap: () => widget.onSyncChanged(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: widget.sync
                    ? PopupMenuButton<double>(
                        tooltip: 'Rate division',
                        padding: EdgeInsets.zero,
                        initialValue: widget.rateBeats,
                        onSelected: widget.onRateBeatsChanged,
                        itemBuilder: (context) => [
                          for (final beats in StutterFxPanel._rateDivisions)
                            PopupMenuItem<double>(
                              value: beats,
                              child: Text(StutterFxPanel._labelForBeats(beats)),
                            ),
                        ],
                        child: _StutterSelectFace(
                          label:
                              StutterFxPanel._labelForBeats(widget.rateBeats),
                          accent: widget.accent,
                        ),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart: _onDragStart,
                        onVerticalDragUpdate: _onDragUpdate,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.045),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.rateMs.round()} ms',
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
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
