part of 'arrangement_view.dart';

class _TrackDropTarget extends StatefulWidget {
  const _TrackDropTarget({
    required this.target,
    required this.intentBuilder,
    required this.onDrop,
    required this.child,
  });

  final TrackSnapshot target;
  final _TrackDropIntent? Function(
    _TrackDragData data,
    TrackSnapshot target,
    _TrackDropZone zone,
  ) intentBuilder;
  final Future<void> Function(_TrackDropIntent intent) onDrop;
  final Widget child;

  @override
  State<_TrackDropTarget> createState() => _TrackDropTargetState();
}
