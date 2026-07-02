import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

abstract final class UserDevicePresetStore {
  static const _key = 'user_device_presets_v1';
  static List<UserDevicePreset> cached = const [];

  static Future<List<UserDevicePreset>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return cached = const [];
    try {
      cached = (jsonDecode(raw) as List)
          .map((v) =>
              UserDevicePreset.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      cached = const [];
    }
    return cached;
  }

  static Future<void> save(UserDevicePreset preset) async {
    final next = [...cached.where((p) => p.id != preset.id), preset]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _write(next);
  }

  static Future<void> delete(String id) async =>
      _write(cached.where((p) => p.id != id).toList());

  static Future<void> rename(String id, String name) async {
    await _write(cached
        .map((p) => p.id == id
            ? UserDevicePreset(
                id: p.id,
                name: name,
                deviceType: p.deviceType,
                presetJson: p.presetJson,
                updatedAt: DateTime.now().millisecondsSinceEpoch)
            : p)
        .toList());
  }

  static Future<void> _write(List<UserDevicePreset> values) async {
    cached = values;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(values.map((p) => p.toJson()).toList()));
  }
}
