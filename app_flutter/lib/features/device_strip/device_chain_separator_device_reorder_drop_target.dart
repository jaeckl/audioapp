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
  /// Avoid setState during drag — rebuilding DragTarget can drop the accept.
  final ValueNotifier<bool> _active = ValueNotifier(false);

  @override
  void dispose() {
    _active.dispose();
    super.dispose();
  }

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
        if (_active.value != accept) _active.value = accept;
        return accept;
      },
      onLeave: (_) {
        if (_active.value) _active.value = false;
      },
      onAcceptWithDetails: (details) {
        _active.value = false;
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
            ValueListenableBuilder<bool>(
              valueListenable: _active,
              builder: (context, active, _) {
                if (!active) return const SizedBox.shrink();
                return Positioned.fill(
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
                );
              },
            ),
          ],
        );
      },
    );
  }
}
