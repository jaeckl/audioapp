part of 'arrangement_view.dart';

class _SampleClipBlock extends StatefulWidget {
  const _SampleClipBlock({
    required this.clip,
    required this.trackAccent,
    required this.highlighted,
    required this.selected,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    this.onDoubleTap,
  });

  final SampleClipSnapshot clip;
  final Color trackAccent;
  final bool highlighted;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final ValueChanged<Offset> onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final void Function({required bool wasAccepted}) onDragEnd;
  final VoidCallback onDragCancel;

  @override
  State<_SampleClipBlock> createState() => _SampleClipBlockState();
}
