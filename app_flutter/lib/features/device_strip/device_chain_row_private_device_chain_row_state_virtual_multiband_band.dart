part of 'device_chain_row.dart';

extension _DeviceChainRowStateVirtualmultibandband on _DeviceChainRowState {
  String _mbBandLabel(MultibandSplitDeviceSnapshot mb, int bandIndex) {
    final labels = MultibandSplitDeviceSnapshot.bandLabels(mb.bandCount);
    if (bandIndex >= 0 && bandIndex < labels.length) return labels[bandIndex];
    return 'B${bandIndex + 1}';
  }

  Widget _virtualMultibandBand(
    BuildContext context,
    MultibandSplitDeviceSnapshot mb,
    int bandIndex,
  ) {
    final accent = DeviceStripTheme.accentForDeviceType(mb.type);
    final bandDevices = mb.bandDevices(bandIndex);
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null) return;
      await widget.onModulationBridgeCall?.call('addDeviceToMultibandBand', {
        'mbId': mb.id,
        'bandIndex': bandIndex,
        'deviceType': type,
      });
    }

    return _VirtualStripChrome(
      accent: accent,
      title: _mbBandLabel(mb, bandIndex),
      children: [
        ..._virtualStripChildRow(
          context,
          bandDevices,
          (child) => widget.onModulationBridgeCall?.call(
                'removeDeviceFromMultibandBand',
                {
                  'mbId': mb.id,
                  'bandIndex': bandIndex,
                  'deviceId': child.id,
                },
              ) ??
              Future.value(),
        ),
        if (bandDevices.length < 8)
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
