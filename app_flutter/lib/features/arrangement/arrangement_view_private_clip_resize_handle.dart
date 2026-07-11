part of 'arrangement_view.dart';

class _ClipResizeHandle extends StatefulWidget {
  const _ClipResizeHandle({
    required this.clipKind,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.onResizeCancel,
  });

  final ClipContentKind clipKind;
  final void Function(DragStartDetails details) onResizeStart;
  final void Function(DragUpdateDetails details) onResizeUpdate;
  final void Function(DragEndDetails details) onResizeEnd;
  final VoidCallback onResizeCancel;

  @override
  State<_ClipResizeHandle> createState() => _ClipResizeHandleState();
}
