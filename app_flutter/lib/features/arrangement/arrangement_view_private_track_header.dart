part of 'arrangement_view.dart';

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({
    required this.track,
    required this.index,
    required this.headerWidth,
    required this.showMixControls,
    required this.selected,
    required this.onTap,
    this.recordArmed = false,
    this.onToggleMute,
    this.onToggleSolo,
    this.onToggleRecordArmed,
    this.onToggleFreeze,
    this.enableDrag = false,
    this.onDragUpdate,
    this.collapsed = false,
    this.onToggleCollapsed,
    this.onLongPressStart,
  });

  final TrackSnapshot track;
  final int index;
  final double headerWidth;
  final bool showMixControls;
  final bool selected;
  final VoidCallback onTap;
  final bool recordArmed;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleSolo;
  final VoidCallback? onToggleRecordArmed;
  final VoidCallback? onToggleFreeze;
  final bool enableDrag;
  final GestureDragUpdateCallback? onDragUpdate;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;
  final GestureLongPressStartCallback? onLongPressStart;

  Widget _groupChevron() {
    if (onToggleCollapsed == null) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleCollapsed,
      child: SizedBox(
        width: 18,
        child: Icon(
          collapsed ? Icons.chevron_right : Icons.expand_more,
          size: 16,
          color: ArrangementTheme.textMuted,
        ),
      ),
    );
  }

  Widget _mixRow() {
    const gap = 4.0;
    const h = ArrangementTimelineMetrics.mixButtonHeight;
    final buttons = <Widget>[
      if (onToggleRecordArmed != null)
        Expanded(
          child: TrackMixButton(
            tooltip: 'Record arm',
            icon: Icons.circle,
            active: recordArmed,
            onTap: onToggleRecordArmed!,
            color: Colors.redAccent,
            height: h,
          ),
        ),
      if (onToggleSolo != null)
        Expanded(
          child: TrackMixButton(
            tooltip: 'Solo',
            icon: Icons.headphones,
            active: track.soloed,
            onTap: onToggleSolo!,
            color: Colors.amber,
            height: h,
          ),
        ),
      if (onToggleMute != null)
        Expanded(
          child: TrackMixButton(
            tooltip: 'Mute',
            icon: Icons.volume_off,
            active: track.muted,
            onTap: onToggleMute!,
            color: Colors.redAccent,
            height: h,
          ),
        ),
      if (onToggleFreeze != null)
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              TrackMixButton(
                tooltip: 'Freeze',
                icon: Icons.ac_unit,
                active: track.freeze.enabled,
                onTap: onToggleFreeze!,
                color: track.freeze.stale
                    ? Colors.amber
                    : const Color(0xFF8EB4FF),
                height: h,
              ),
              if (track.freeze.enabled && track.freeze.stale)
                const Positioned(
                  right: 2,
                  top: 2,
                  child: Icon(
                    Icons.circle,
                    size: 7,
                    color: Colors.amberAccent,
                  ),
                ),
            ],
          ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: h,
      child: Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            buttons[i],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = TrackLaneIcon.iconForTrack(track, index);
    final accent = TrackLaneColor.colorForTrack(track, index);
    final iconColor = track.isGroup
        ? ArrangementTheme.masterIcon
        : selected
            ? accent
            : accent.withValues(alpha: 0.75);

    final nameRow = Row(
      children: [
        _groupChevron(),
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            track.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: ArrangementTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ),
      ],
    );

    final headerBg = Color.alphaBlend(
      TrackLaneColor.headerWash(accent, selected: selected),
      selected ? ArrangementTheme.headerSelected : ArrangementTheme.cardBackground,
    );
    final lane = Material(
      color: headerBg,
      child: Container(
        width: headerWidth,
        height: ArrangementTimelineMetrics.trackLaneHeight,
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accent.withValues(alpha: 0.85), width: 3),
            bottom: const BorderSide(color: ArrangementTheme.divider),
            right: const BorderSide(color: ArrangementTheme.border),
          ),
        ),
        // BoxDecoration borders inset the child (bottom 1px), so name row
        // must flex — fixed 28+4+30 overflows the padded lane by 1.
        child: showMixControls
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onTap,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: nameRow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _mixRow(),
                ],
              )
            : InkWell(
                onTap: onTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (track.parentGroupId.isNotEmpty)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: ArrangementTheme.masterIcon
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: track.parentGroupId.isNotEmpty ? 6 : 0,
                      ),
                      child: Icon(icon, size: 22, color: iconColor),
                    ),
                    if (onToggleCollapsed != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: _groupChevron(),
                      ),
                  ],
                ),
              ),
      ),
    );

    final content = Tooltip(
      message: track.name,
      triggerMode: enableDrag ? TooltipTriggerMode.manual : null,
      child: Semantics(
        label: track.name,
        selected: selected,
        button: true,
        child: showMixControls
            ? lane
            : GestureDetector(
                onTap: onTap,
                onLongPressStart: onLongPressStart,
                child: lane,
              ),
      ),
    );
    if (!enableDrag) return content;
    return LongPressDraggable<_TrackDragData>(
      data: _TrackDragData(track),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _TrackDragFeedback(track: track),
      childWhenDragging: Opacity(opacity: 0.28, child: content),
      onDragStarted: HapticFeedback.selectionClick,
      onDragUpdate: onDragUpdate,
      child: content,
    );
  }
}
