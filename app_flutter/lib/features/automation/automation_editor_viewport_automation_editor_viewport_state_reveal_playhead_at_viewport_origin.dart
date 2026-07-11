part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateRevealplayheadatviewportorigin
    on AutomationEditorViewportState {
  void _revealPlayheadAtViewportOrigin(double beat) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!timelinePlayheadIsSticky(
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: _horizontalScrollOffset,
      )) {
        return;
      }
      final jumped = jumpTimelineScrollToRevealBeatNow(
        horizontal: _horizontal,
        ruler: _ruler,
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
      );
      if (jumped) {
        if (mounted) setState(() {});
        return;
      }
      jumpTimelineScrollToRevealBeat(
        horizontal: _horizontal,
        ruler: _ruler,
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        onComplete: () {
          if (mounted) setState(() {});
        },
      );
    });
  }
}
