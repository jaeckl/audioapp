part of 'routing_device_panel.dart';

class RoutingSourceOption {
  const RoutingSourceOption(
      {required this.id,
      required this.label,
      required this.isMidi,
      required this.trackId,
      required this.deviceIndex,
      this.disabled = false,
      this.disabledReason});
  final String id;
  final String label;
  final bool isMidi;
  final String trackId;
  final int deviceIndex;
  final bool disabled;
  final String? disabledReason;
}
