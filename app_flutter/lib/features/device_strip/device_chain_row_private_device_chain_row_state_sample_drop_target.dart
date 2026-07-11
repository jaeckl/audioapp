part of 'device_chain_row.dart';

extension _DeviceChainRowStateSampledroptarget on _DeviceChainRowState {
  Widget _sampleDropTarget({
    required Widget child,
    required bool enabled,
    required Future<void> Function(SampleClipDragData sample) onAccept,
  }) {
    if (!enabled) return child;
    return DragTarget<SampleClipDragData>(
      onWillAcceptWithDetails: (details) => details.data.sampleId.isNotEmpty,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, _) {
        final active = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: active
              ? BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(DeviceStripTheme.cardRadius + 4),
                  border: Border.all(
                    color: DeviceStripTheme.samplerAccent,
                    width: 2,
                  ),
                )
              : null,
          child: child,
        );
      },
    );
  }
}
