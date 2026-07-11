part of 'device_strip_slot.dart';

extension DeviceStripSlotStateEnsureparamdescriptorsOperation
    on _DeviceStripSlotState {
  void _ensureParamDescriptors() {
    if (_hasCustomEditor) return;
    final type = widget.device.type;
    if (_paramCache.containsKey(type)) {
      _cachedParams = _paramCache[type];
      return;
    }
    final fetcher = widget.onGetParamDescriptors;
    if (fetcher == null) return;
    fetcher(type).then((params) {
      if (!mounted) return;
      _paramCache[type] = params;
      if (widget.device.type == type) {
        setState(() => _cachedParams = params);
      }
    });
  }
}
