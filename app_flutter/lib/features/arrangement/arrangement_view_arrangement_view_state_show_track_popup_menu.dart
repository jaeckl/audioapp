part of 'arrangement_view.dart';

extension ArrangementViewStateShowtrackpopupmenuOperation on ArrangementViewState {
Future<void> _showTrackPopupMenu(
    TrackSnapshot track,
    Offset globalPosition,
    double desiredBeat,
  ) async {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox == null) {
      return;
    }

    final menuPosition = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & overlayBox.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: menuPosition,
      color: ArrangementTheme.menuBackground,
      items: [
        if (!track.isGroup && !track.freeze.enabled)
          const PopupMenuItem(
            value: 'midi',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.piano_outlined, size: 22),
              title: Text('Add MIDI Clip'),
            ),
          ),
        if (!track.isGroup && !track.freeze.enabled)
          const PopupMenuItem(
            value: 'audio',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.audio_file_outlined, size: 22),
              title: Text('Add Audio Clip'),
            ),
          ),
        if (widget.onAddAutomationClip != null && !track.freeze.enabled)
          const PopupMenuItem(
            value: 'automation',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.show_chart_outlined,
                  size: 22, color: Color(0xFFB48CFF)),
              title: Text('Add Automation Clip'),
            ),
          ),
        if (!track.isGroup && widget.onSetTrackGroup != null)
          for (final group
              in widget.snapshot.tracks.where((item) => item.isGroup))
            PopupMenuItem(
              value: 'group:${group.id}',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined, size: 22),
                title: Text('Move to ${group.name}'),
                trailing: track.parentGroupId == group.id
                    ? const Icon(Icons.check, size: 18)
                    : null,
              ),
            ),
        if (!track.isGroup &&
            track.parentGroupId.isNotEmpty &&
            widget.onSetTrackGroup != null)
          const PopupMenuItem(
            value: 'ungroup',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.drive_file_move_outline, size: 22),
              title: Text('Remove from group'),
            ),
          ),
        if (widget.onDeleteTrack != null)
          const PopupMenuItem(
            value: 'delete_track',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
              title: Text('Delete track'),
            ),
          ),
      ],
    );
    if (!mounted || action == null) {
      return;
    }

    if (action == 'midi') {
      final startBeat = _placementForTrack(
        track,
        desiredBeat,
        ArrangementTimelineMetrics.defaultMidiClipLengthBeats,
      );
      widget.onAddMidiClip(track.id, startBeat);
    } else if (action == 'audio') {
      widget.onAddAudioClip(track.id, desiredBeat);
    } else if (action == 'automation') {
      final startBeat = _placementForTrack(
        track,
        desiredBeat,
        ArrangementTimelineMetrics.defaultMidiClipLengthBeats,
      );
      widget.onAddAutomationClip!(track.id, startBeat);
    } else if (action.startsWith('group:')) {
      await widget.onSetTrackGroup?.call(track.id, action.substring(6));
    } else if (action == 'ungroup') {
      await widget.onSetTrackGroup?.call(track.id, null);
    } else if (action == 'delete_track') {
      widget.onDeleteTrack?.call(track.id);
    }
  }
}
