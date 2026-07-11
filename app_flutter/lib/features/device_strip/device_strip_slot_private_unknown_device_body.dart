part of 'device_strip_slot.dart';

class _UnknownDeviceBody extends StatelessWidget {
  const _UnknownDeviceBody({required this.deviceType});

  final String deviceType;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        deviceType,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Colors.white54),
      ),
    );
  }
}
