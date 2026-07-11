import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

part 'curve_library_store_curve_library_resource.dart';
abstract final class CurveLibraryStore {
  static const _storageKey = 'curve_library_resources_v1';

  static const factoryResources = <CurveLibraryResource>[
    CurveLibraryResource(
      id: 'curve:factory:ramp-up',
      name: 'Ramp Up',
      positions: [0, 1],
      values: [0, 1],
      shapes: [0, 0],
      factory: true,
    ),
    CurveLibraryResource(
      id: 'curve:factory:sidechain',
      name: 'Sidechain Pump',
      positions: [0, 0.08, 0.35, 1],
      values: [0, 0, 0.82, 1],
      shapes: [0, 1, 1, 0],
      factory: true,
    ),
  ];

  static Future<List<CurveLibraryResource>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [...factoryResources];
    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return [
        ...factoryResources,
        ...values.map((value) => CurveLibraryResource.fromJson(
              value as Map<String, dynamic>,
            )),
      ];
    } catch (_) {
      return [...factoryResources];
    }
  }

  static Future<void> save(CurveLibraryResource resource) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (await load()).where((item) => !item.factory).toList();
    existing.removeWhere((item) => item.id == resource.id);
    existing.add(resource);
    await prefs.setString(
      _storageKey,
      jsonEncode(existing.map((item) => item.toJson()).toList()),
    );
  }
}
