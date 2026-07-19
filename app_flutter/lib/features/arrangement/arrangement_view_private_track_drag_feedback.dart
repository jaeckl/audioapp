part of 'arrangement_view.dart';

class _TrackDragFeedback extends StatelessWidget {
  const _TrackDragFeedback({required this.track});

  final TrackSnapshot track;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 132, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ArrangementTheme.dragFeedbackFill,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: ArrangementTheme.dragFeedbackBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              track.isGroup ? Icons.folder_outlined : Icons.drag_indicator,
              size: 20,
              color: track.isGroup
                  ? ArrangementTheme.masterIcon
                  : ArrangementTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                track.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ArrangementTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
