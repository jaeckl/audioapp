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
          color: const Color(0xFF30303D),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF8E8CFF), width: 1.5),
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
              color: track.isGroup ? Colors.amber.shade200 : Colors.white70,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                track.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
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
