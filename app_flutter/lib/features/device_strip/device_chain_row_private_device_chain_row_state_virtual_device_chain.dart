part of 'device_chain_row.dart';

extension _DeviceChainRowStateVirtualdevicechain on _DeviceChainRowState {
  Widget _virtualDeviceChain(BuildContext context, ChainDeviceSnapshot chain) {
    final accent = DeviceStripTheme.accentForDeviceType('device_chain');
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null) return;
      await widget.onModulationBridgeCall?.call('addDeviceToChain', {
        'chainId': chain.id,
        'deviceType': type,
      });
    }

    return _VirtualStripChrome(
      accent: accent,
      title: 'CHAIN',
      children: [
        ..._virtualStripChildRow(
          context,
          chain.devices,
          (child) => widget.onModulationBridgeCall?.call(
                'removeDeviceFromChain',
                {'chainId': chain.id, 'deviceId': child.id},
              ) ??
              Future.value(),
        ),
        if (chain.devices.length < 8)
          SizedBox(
            width: DeviceStripMetrics.separatorWidth,
            child: Center(
                child: DeviceInsertSlot(
                    accentColor: accent, onPressed: addDevice)),
          ),
      ],
    );
  }
}
