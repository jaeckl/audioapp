part of 'device_chain_row.dart';

extension _DeviceChainRowStateLeadinginsert on _DeviceChainRowState {
  Widget _leadingInsert(BuildContext context) {
    return SizedBox(
      width: DeviceStripMetrics.separatorWidth + 120,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'No devices',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white38),
              ),
            ),
          ),
          DeviceChainSeparator(
            active: widget.playing,
            gain: 0.35,
            onInsert: widget.track.canInsertDevices
                ? () => widget.onInsertDevice(0)
                : null,
          ),
        ],
      ),
    );
  }
}
