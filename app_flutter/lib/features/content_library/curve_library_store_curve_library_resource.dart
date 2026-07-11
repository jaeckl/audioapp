part of 'curve_library_store.dart';

class CurveLibraryResource {
  const CurveLibraryResource({
    required this.id,
    required this.name,
    required this.positions,
    required this.values,
    required this.shapes,
    this.factory = false,
  });

  final String id;
  final String name;
  final List<double> positions;
  final List<double> values;
  final List<int> shapes;
  final bool factory;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'positions': positions,
        'values': values,
        'shapes': shapes,
      };

  factory CurveLibraryResource.fromJson(Map<String, dynamic> json) =>
      CurveLibraryResource(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Curve',
        positions: (json['positions'] as List<dynamic>? ?? const [])
            .map((value) => (value as num).toDouble())
            .toList(),
        values: (json['values'] as List<dynamic>? ?? const [])
            .map((value) => (value as num).toDouble())
            .toList(),
        shapes: (json['shapes'] as List<dynamic>? ?? const [])
            .map((value) => (value as num).toInt())
            .toList(),
      );
}
