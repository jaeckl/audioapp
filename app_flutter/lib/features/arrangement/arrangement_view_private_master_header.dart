part of 'arrangement_view.dart';

class _MasterHeader extends StatelessWidget {
  const _MasterHeader({
    required this.master,
    required this.width,
    required this.selected,
    required this.onTap,
    required this.onToggleMute,
    this.onLongPressStart,
  });

  final MasterTrackSnapshot master;
  final double width;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleMute;
  final GestureLongPressStartCallback? onLongPressStart;

  @override
  Widget build(BuildContext context) {
    final showMix = ArrangementTimelineMetrics.headerShowsMixControls(width);
    return Material(
      color: selected
          ? ArrangementTheme.headerSelected
          : ArrangementTheme.masterHeader,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: onLongPressStart,
        child: Container(
          width: width,
          height: ArrangementTimelineMetrics.trackLaneHeight,
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: ArrangementTheme.masterBorder),
              right: const BorderSide(color: ArrangementTheme.border),
              bottom: BorderSide(color: ArrangementTheme.masterBorder),
            ),
          ),
          child: showMix
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.speaker_outlined,
                              size: 18, color: ArrangementTheme.masterIcon),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              master.name,
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: ArrangementTimelineMetrics.mixButtonHeight,
                      child: TrackMixButton(
                        tooltip: 'Mute master',
                        icon: Icons.volume_off,
                        active: master.muted,
                        onTap: onToggleMute,
                        color: Colors.redAccent,
                        height: ArrangementTimelineMetrics.mixButtonHeight,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(Icons.speaker_outlined,
                      size: 22, color: ArrangementTheme.masterIcon),
                ),
        ),
      ),
    );
  }
}
