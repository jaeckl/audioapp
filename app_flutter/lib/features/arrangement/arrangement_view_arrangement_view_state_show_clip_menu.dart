part of 'arrangement_view.dart';

extension ArrangementViewStateShowclipmenuOperation on ArrangementViewState {
Future<void> _showClipMenu(String clipId) async {
    if (widget.onDeleteClip == null &&
        widget.onDuplicateClip == null &&
        widget.onSetClipLoopContent == null) {
      return;
    }
    final loopContent = _clipLoopContent(clipId);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A22),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loopContent != null && widget.onSetClipLoopContent != null)
              ListTile(
                leading: Icon(
                  loopContent ? Icons.loop : Icons.loop_outlined,
                ),
                title: Text(loopContent ? 'Disable loop' : 'Loop content'),
                onTap: () => Navigator.pop(
                  context,
                  loopContent ? 'loop_off' : 'loop_on',
                ),
              ),
            if (widget.onDuplicateClip != null)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Duplicate clip'),
                onTap: () => Navigator.pop(context, 'duplicate'),
              ),
            if (widget.onDeleteClip != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete clip'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'loop_on') {
      await widget.onSetClipLoopContent?.call(
        clipId: clipId,
        loopContent: true,
      );
    } else if (action == 'loop_off') {
      await widget.onSetClipLoopContent?.call(
        clipId: clipId,
        loopContent: false,
      );
    } else if (action == 'duplicate') {
      widget.onDuplicateClip?.call(clipId);
    } else if (action == 'delete') {
      widget.onDeleteClip?.call(clipId);
    }
  }
}
