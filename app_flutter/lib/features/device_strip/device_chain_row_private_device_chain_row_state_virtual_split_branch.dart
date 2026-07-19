part of 'device_chain_row.dart';

extension _DeviceChainRowStateVirtualsplitbranch on _DeviceChainRowState {
  String _splitBranchLabel(SplitDeviceSnapshot split, int branchIndex) {
    if (split.isMidSide) return branchIndex == 0 ? 'MID' : 'SIDE';
    return branchIndex == 0 ? 'L' : 'R';
  }

  Widget _virtualSplitBranch(
    BuildContext context,
    SplitDeviceSnapshot split,
    int branchIndex,
  ) {
    final accent = DeviceStripTheme.accentForDeviceType(split.type);
    final branchDevices = split.branchDevices(branchIndex);
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null) return;
      await widget.onModulationBridgeCall?.call('addDeviceToSplitBranch', {
        'splitId': split.id,
        'branchIndex': branchIndex,
        'deviceType': type,
      });
    }

    return _VirtualStripChrome(
      accent: accent,
      title: _splitBranchLabel(split, branchIndex),
      children: [
        ..._virtualStripChildRow(
          context,
          branchDevices,
          (child) => widget.onModulationBridgeCall?.call(
                'removeDeviceFromSplitBranch',
                {
                  'splitId': split.id,
                  'branchIndex': branchIndex,
                  'deviceId': child.id,
                },
              ) ??
              Future.value(),
        ),
        if (branchDevices.length < 8)
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
