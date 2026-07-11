import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_device_preset_store_user_device_preset.dart';
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
