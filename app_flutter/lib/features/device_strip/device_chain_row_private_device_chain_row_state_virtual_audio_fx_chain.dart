part of 'device_chain_row.dart';

extension _DeviceChainRowStateVirtualaudiofxchain on _DeviceChainRowState {
  Widget _virtualAudioFxChain(BuildContext context, DeviceSnapshot synth) {
    const accent = Color(0xFF00FF33);
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null) return;
      await widget.onModulationBridgeCall?.call('addDeviceToSynthAudioFx', {
        'deviceId': synth.id,
        'deviceType': type,
      });
    }

    return _VirtualStripChrome(
      accent: accent,
      title: DeviceCapabilities.sidechainFxHosts.contains(synth.type)
          ? 'SC FX'
          : 'FX',
      children: [
        ..._virtualStripChildRow(
          context,
          synth.audioFxDevices,
          (child) => widget.onModulationBridgeCall?.call(
                'removeDeviceFromSynthAudioFx',
                {'deviceId': synth.id, 'subDeviceId': child.id},
              ) ??
              Future.value(),
        ),
        if (synth.audioFxDevices.length < 8)
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
