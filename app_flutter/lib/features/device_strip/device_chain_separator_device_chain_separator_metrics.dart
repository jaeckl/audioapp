part of 'device_chain_separator.dart';

extension DeviceChainSeparatorMetrics on DeviceSnapshot {
  double get chainVuGain => _deviceGain(this);
}
