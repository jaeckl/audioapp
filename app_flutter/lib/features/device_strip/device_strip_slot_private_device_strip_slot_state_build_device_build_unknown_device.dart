part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildunknowndeviceOperation
    on _DeviceStripSlotState {
  Widget _buildUnknownDevice(BuildContext context, double contentHeight) {
    final params = _cachedParams ?? [];
    return SizedBox(
      width: _cardWidth - DeviceStripTheme.accentStripeWidth,
      child: params.isEmpty
          ? _UnknownDeviceBody(deviceType: widget.device.type)
          : GenericParamEditor(
              params: params,
              currentValues: _deviceCurrentValues,
              modulationAmounts: _modulationAmounts,
              onParameterChanged: (paramId, value) =>
                  widget.onSamplerParameterChanged(paramId, value),
            ),
    );
  }
}
