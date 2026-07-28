part of 'arrangement_view.dart';

/// Master strip — same clip lane chrome as tracks (warm wash only).
class _MasterLane extends StatelessWidget {
  const _MasterLane({
    required this.track,
    required this.selected,
    required this.onTap,
    required this.pixelsPerBeat,
    required this.timelineEndBeat,
    required this.viewportWidthPx,
    required this.draggingClipId,
    required this.selectedClipId,
    this.highlightedClipId,
    required this.onClipTap,
    required this.onSampleClipTap,
    required this.onClipSelected,
    required this.onClipDragStart,
    required this.onClipDragUpdate,
    required this.onClipDragEnd,
    required this.onSampleClipDragUpdate,
    required this.onSampleClipDragEnd,
    required this.onClipDragCancel,
    required this.onLongPressStart,
    required this.onResizeClipStart,
    required this.onResizeClipUpdate,
    required this.onResizeClipEnd,
    required this.onResizeClipCancel,
    required this.previewLengthFor,
    required this.liveMidiPreviewNotes,
    required this.liveMidiPreviewClips,
    this.onDeleteClip,
    this.onClipMenu,
    this.automationLinkClipId,
    this.onAutomationLinkToggle,
    this.onAutomationClipDoubleTap,
  });

  final TrackSnapshot track;
  final bool selected;
  final VoidCallback onTap;
  final double pixelsPerBeat;
  final double timelineEndBeat;
  final double viewportWidthPx;
  final String? draggingClipId;
  final String? selectedClipId;
  final String? highlightedClipId;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final void Function(String trackId, SampleClipSnapshot clip) onSampleClipTap;
  final void Function(String trackId, String clipId) onClipSelected;
  final void Function({
    required String trackId,
    required String clipId,
    required double lengthBeats,
    required bool isMidi,
    required double originalStartBeat,
    required Offset globalPosition,
    MidiClipSnapshot? midiClip,
    SampleClipSnapshot? sampleClip,
    AutomationClipSnapshot? automationClip,
  }) onClipDragStart;
  final GestureLongPressMoveUpdateCallback onClipDragUpdate;
  final GestureLongPressEndCallback onClipDragEnd;
  final ValueChanged<Offset> onSampleClipDragUpdate;
  final void Function({required bool wasAccepted}) onSampleClipDragEnd;
  final VoidCallback onClipDragCancel;
  final GestureLongPressStartCallback onLongPressStart;
  final void Function({
    required String clipId,
    required String trackId,
    required double startBeat,
    required double lengthBeats,
    required Offset globalPosition,
    required double adjacentClipStartBeat,
    required ClipContentKind kind,
  }) onResizeClipStart;
  final void Function(DragUpdateDetails details) onResizeClipUpdate;
  final void Function(DragEndDetails details) onResizeClipEnd;
  final VoidCallback onResizeClipCancel;
  final double? Function(String clipId) previewLengthFor;
  final Map<String, List<MidiNoteSnapshot>> liveMidiPreviewNotes;
  final List<MidiClipSnapshot> liveMidiPreviewClips;
  final void Function(String clipId)? onDeleteClip;
  final void Function(String clipId)? onClipMenu;
  final String? automationLinkClipId;
  final void Function(String clipId)? onAutomationLinkToggle;
  final void Function(String trackId, AutomationClipSnapshot clip)?
      onAutomationClipDoubleTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? ArrangementTheme.masterLaneWash.withValues(alpha: 0.55)
            : ArrangementTheme.masterLaneWash,
        border: Border(
          top: BorderSide(color: ArrangementTheme.masterBorder),
        ),
      ),
      child: _TrackLane(
        track: track,
        trackAccent: TrackLaneColor.master,
        selected: selected,
        onTap: onTap,
        pixelsPerBeat: pixelsPerBeat,
        timelineEndBeat: timelineEndBeat,
        viewportWidthPx: viewportWidthPx,
        draggingClipId: draggingClipId,
        selectedClipId: selectedClipId,
        highlightedClipId: highlightedClipId,
        onClipTap: onClipTap,
        onSampleClipTap: onSampleClipTap,
        onClipSelected: onClipSelected,
        onClipDragStart: onClipDragStart,
        onClipDragUpdate: onClipDragUpdate,
        onClipDragEnd: onClipDragEnd,
        onSampleClipDragUpdate: onSampleClipDragUpdate,
        onSampleClipDragEnd: onSampleClipDragEnd,
        onClipDragCancel: onClipDragCancel,
        onLongPressStart: onLongPressStart,
        onResizeClipStart: onResizeClipStart,
        onResizeClipUpdate: onResizeClipUpdate,
        onResizeClipEnd: onResizeClipEnd,
        onResizeClipCancel: onResizeClipCancel,
        previewLengthFor: previewLengthFor,
        liveMidiPreviewNotes: liveMidiPreviewNotes,
        liveMidiPreviewClips: liveMidiPreviewClips,
        onDeleteClip: onDeleteClip,
        onClipMenu: onClipMenu,
        automationLinkClipId: automationLinkClipId,
        onAutomationLinkToggle: onAutomationLinkToggle,
        onAutomationClipDoubleTap: onAutomationClipDoubleTap,
      ),
    );
  }
}
