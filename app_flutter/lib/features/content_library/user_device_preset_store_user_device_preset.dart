part of 'user_device_preset_store.dart';

class UserDevicePreset {
  const UserDevicePreset(
      {required this.id,
      required this.name,
      required this.deviceType,
      required this.presetJson,
      required this.updatedAt});
  final String id, name, deviceType, presetJson;
  final int updatedAt;
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'deviceType': deviceType,
        'presetJson': presetJson,
        'updatedAt': updatedAt
      };
  factory UserDevicePreset.fromJson(Map<String, dynamic> value) =>
      UserDevicePreset(
          id: value['id'] as String,
          name: value['name'] as String,
          deviceType: value['deviceType'] as String,
          presetJson: value['presetJson'] as String,
          updatedAt: value['updatedAt'] as int? ?? 0);
}
