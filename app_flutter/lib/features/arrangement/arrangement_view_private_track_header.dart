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

  Widget _groupChevron(ThemeData theme) {
    if (onToggleCollapsed == null) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleCollapsed,
      child: SizedBox(
        width: 15,
        child: Icon(
          collapsed ? Icons.chevron_right : Icons.expand_more,
          size: 15,
          color: Colors.white70,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = TrackLaneIcon.iconForTrack(track, index);
    final iconColor = track.isGroup
        ? Colors.amber.shade200
        : selected
            ? theme.colorScheme.primary
            : Colors.white70;

    final lane = Material(
      color: selected ? const Color(0xFF2D2D3A) : Colors.transparent,
      child: Container(
        width: headerWidth,
        height: ArrangementTimelineMetrics.trackLaneHeight,
        padding: EdgeInsets.only(
          left: track.parentGroupId.isNotEmpty ? 4 : 2,
          right: showMixControls ? 4 : 0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: showMixControls
            ? Row(
                children: [
                  _groupChevron(theme),
                  Expanded(
                    child: InkWell(
                      onTap: onTap,
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: iconColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              track.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onToggleRecordArmed != null) ...[
                    TrackMixButton(
                      label: 'R',
                      active: recordArmed,
                      onTap: onToggleRecordArmed!,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (onToggleSolo != null) ...[
                    TrackMixButton(
                      label: 'S',
                      active: track.soloed,
                      onTap: onToggleSolo!,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (onToggleMute != null)
                    TrackMixButton(
                      label: 'M',
                      active: track.muted,
                      onTap: onToggleMute!,
                      color: Colors.redAccent,
                    ),
                  if (onToggleFreeze != null) ...[
                    const SizedBox(width: 4),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        TrackMixButton(
                          label: 'F',
                          active: track.freeze.enabled,
                          onTap: onToggleFreeze!,
                          color: track.freeze.stale
                              ? Colors.amber
                              : const Color(0xFF8EB4FF),
                        ),
                        if (track.freeze.enabled && track.freeze.stale)
                          const Positioned(
                            right: -1,
                            top: -1,
                            child: Icon(
                              Icons.circle,
                              size: 7,
                              color: Colors.amberAccent,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              )
            : InkWell(
                onTap: onTap,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (track.parentGroupId.isNotEmpty)
                      Positioned(
                        left: 3,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.45),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: track.parentGroupId.isNotEmpty ? 7 : 0,
                      ),
                      child: Icon(icon, size: 22, color: iconColor),
                    ),
                    if (onToggleCollapsed != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: _groupChevron(theme),
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
