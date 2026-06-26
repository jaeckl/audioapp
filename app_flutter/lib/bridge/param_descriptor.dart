/// Parameter metadata from native engine.
class DeviceParamDescriptor {
  final String stableName;
  final String displayName;
  final double defaultValue;
  final double min;
  final double max;
  final bool automatable;
  final bool modulatable;

  const DeviceParamDescriptor({
    required this.stableName,
    required this.displayName,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.automatable,
    required this.modulatable,
  });

  factory DeviceParamDescriptor.fromMap(Map<String, dynamic> map) {
    return DeviceParamDescriptor(
      stableName: map['stableName'] as String? ?? '',
      displayName: map['displayName'] as String? ?? map['stableName'] as String? ?? '',
      defaultValue: (map['defaultValue'] as num?)?.toDouble() ?? 0.0,
      min: (map['min'] as num?)?.toDouble() ?? 0.0,
      max: (map['max'] as num?)?.toDouble() ?? 1.0,
      automatable: map['automatable'] == true,
      modulatable: map['modulatable'] == true,
    );
  }
}