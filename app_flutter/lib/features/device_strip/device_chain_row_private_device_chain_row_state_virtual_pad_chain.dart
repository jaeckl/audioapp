part of 'device_chain_row.dart';

extension _DeviceChainRowStateVirtualpadchain on _DeviceChainRowState {
  Widget _virtualPadChain(
      BuildContext context, DrumMachineDeviceSnapshot machine) {
    final note = widget.drumSelectedNoteFor?.call(machine.id) ?? 36;
    final pad = machine.padForNote(note);
    final accent = DeviceStripTheme.accentForDeviceType('drum_machine');
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null) return;
      await widget.onModulationBridgeCall?.call('addDeviceToDrumPad', {
        'drumMachineId': machine.id,
        'note': note,
        'deviceType': type,
      });
    }

    return _VirtualStripChrome(
      accent: accent,
      title: 'PAD $note',
      children: [
        if (pad.devices.isEmpty)
          SizedBox(
            width: DeviceStripMetrics.separatorWidth,
            child: Center(
                child: DeviceInsertSlot(
              accentColor: accent,
              onPressed: addDevice,
            )),
          )
        else ...[
          ..._virtualStripChildRow(
            context,
            pad.devices,
            (child) => widget.onModulationBridgeCall?.call(
                  'removeDeviceFromDrumPad',
                  {
                    'drumMachineId': machine.id,
                    'note': note,
                    'deviceId': child.id,
                  },
                ) ??
                Future.value(),
          ),
          if (pad.devices.length < 4)
            SizedBox(
              width: DeviceStripMetrics.separatorWidth,
              child: Center(
                  child: DeviceInsertSlot(
                accentColor: accent,
                onPressed: addDevice,
              )),
            ),
        ],
      ],
    );
  }
}
