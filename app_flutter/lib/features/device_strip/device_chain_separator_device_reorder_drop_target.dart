part of 'device_chain_separator.dart';

class DeviceReorderDropTarget extends StatefulWidget {
  const DeviceReorderDropTarget({
    super.key,
    required this.track,
    required this.visibleInsertAfterIndex,
    required this.onMove,
    required this.child,
  });

  final TrackSnapshot track;
  final int visibleInsertAfterIndex;
  final Future<void> Function(String deviceId, int toIndex) onMove;
  final Widget child;

  @override
  State<DeviceReorderDropTarget> createState() =>
      _DeviceReorderDropTargetState();
}

class _DeviceReorderDropTargetState extends State<DeviceReorderDropTarget> {
  bool _active = false;

  bool _canAccept(DeviceDragData data) {
    if (data.trackId != widget.track.id) return false;
    return !deviceMoveWouldBeNoOp(
      data.visibleIndex,
      widget.visibleInsertAfterIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return DragTarget<DeviceDragData>(
      onWillAcceptWithDetails: (details) {
        final accept = _canAccept(details.data);
        if (_active != accept) {
          setState(() => _active = accept);
        }
        return accept;
      },
      onLeave: (_) {
        if (_active) setState(() => _active = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _active = false);
        if (!_canAccept(details.data)) return;
        final toIndex = deviceMoveTargetIndex(
          widget.track,
          widget.visibleInsertAfterIndex,
        );
        widget.onMove(details.data.deviceId, toIndex);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_active)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 3,
                      height: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: accent,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
