part of 'device_chain_row.dart';

extension _DeviceChainRowStateVirtualspectralloudband on _DeviceChainRowState {
  Widget _virtualSpectralLoudBand(
    BuildContext context,
    SpectralLoudSplitDeviceSnapshot device,
    int bandIndex,
  ) {
    final accent = DeviceStripTheme.spectralLoudBandColor(bandIndex);
    final bandDevices = device.bandDevices(bandIndex);
    final label = SpectralLoudSplitDeviceSnapshot.bandLabels[bandIndex];
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null) return;
      await widget.onModulationBridgeCall?.call('addDeviceToSpectralLoudBand', {
        'deviceId': device.id,
        'bandIndex': bandIndex,
        'deviceType': type,
      });
    }

    return _spectralVirtualStrip(
      accent: accent,
      title: label,
      devices: bandDevices,
      onAdd: addDevice,
      removeMethod: 'removeDeviceFromSpectralLoudBand',
      removeArgs: (childId) => {
        'deviceId': device.id,
        'bandIndex': bandIndex,
        'childId': childId,
      },
    );
  }

  Widget _virtualSpectralLoudPreFx(
    BuildContext context,
    SpectralLoudSplitDeviceSnapshot device,
  ) {
    final accent = DeviceStripTheme.accentForDeviceType(device.type);
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null) return;
      await widget.onModulationBridgeCall?.call('addDeviceToSpectralLoudPreFx', {
        'deviceId': device.id,
        'deviceType': type,
      });
    }

    return _spectralVirtualStrip(
      accent: accent,
      title: 'PRE',
      devices: device.preFxDevices,
      onAdd: addDevice,
      removeMethod: 'removeDeviceFromSpectralLoudPreFx',
      removeArgs: (childId) => {
        'deviceId': device.id,
        'childId': childId,
      },
    );
  }

  Widget _virtualSpectralLoudPostFx(
    BuildContext context,
    SpectralLoudSplitDeviceSnapshot device,
  ) {
    final accent = DeviceStripTheme.accentForDeviceType(device.type);
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null) return;
      await widget.onModulationBridgeCall
          ?.call('addDeviceToSpectralLoudPostFx', {
        'deviceId': device.id,
        'deviceType': type,
      });
    }

    return _spectralVirtualStrip(
      accent: accent,
      title: 'POST',
      devices: device.postFxDevices,
      onAdd: addDevice,
      removeMethod: 'removeDeviceFromSpectralLoudPostFx',
      removeArgs: (childId) => {
        'deviceId': device.id,
        'childId': childId,
      },
    );
  }

  Widget _spectralVirtualStrip({
    required Color accent,
    required String title,
    required List<DeviceSnapshot> devices,
    required Future<void> Function() onAdd,
    required Map<String, dynamic> Function(String childId) removeArgs,
    required String removeMethod,
  }) {
    return Builder(
      builder: (context) => _VirtualStripChrome(
        accent: accent,
        title: title,
        children: [
          ..._virtualStripChildRow(
            context,
            devices,
            (child) => widget.onModulationBridgeCall
                    ?.call(removeMethod, removeArgs(child.id)) ??
                Future.value(),
          ),
          if (devices.length < 8)
            SizedBox(
              width: DeviceStripMetrics.separatorWidth,
              child: Center(
                  child: DeviceInsertSlot(
                      accentColor: accent, onPressed: onAdd)),
            ),
        ],
      ),
    );
  }
}
