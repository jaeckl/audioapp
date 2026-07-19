part of 'device_chain_row.dart';

extension _DeviceChainRowStateVirtualnotefxchain on _DeviceChainRowState {
  Widget _virtualNoteFxChain(BuildContext context, DeviceSnapshot synth) {
    const accent = Color(0xFFF9FF00);
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null) return;
      await widget.onModulationBridgeCall?.call('addDeviceToSynthNoteFx', {
        'deviceId': synth.id,
        'deviceType': type,
      });
    }

    return _VirtualStripChrome(
      accent: accent,
      title: 'NOTE FX',
      children: [
        ..._virtualStripChildRow(
          context,
          synth.noteFxDevices,
          (child) => widget.onModulationBridgeCall?.call(
                'removeDeviceFromSynthNoteFx',
                {'deviceId': synth.id, 'subDeviceId': child.id},
              ) ??
              Future.value(),
        ),
        if (synth.noteFxDevices.length < 8)
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
