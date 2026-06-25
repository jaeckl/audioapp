/// Shared parsing helpers for native bridge JSON maps.
/// Current bridge protocol version. Must match C++ kBridgeProtocolVersion.
const int kBridgeProtocolVersion = 1;

bool readEngineBool(dynamic value, {required bool defaultValue}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return defaultValue;
}

double readEngineDouble(dynamic value, {required double defaultValue}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Validate bridge protocol version from response map.
/// Returns null if OK, or error message string on mismatch.
String? checkBridgeProtocolVersion(Map<dynamic, dynamic> map) {
  final version = map['protocolVersion'];
  if (version == null) return null; // legacy responses without version field
  if (version is num && version.toInt() == kBridgeProtocolVersion) return null;
  return 'Bridge protocol version mismatch: got $version, expected $kBridgeProtocolVersion. '
      'Update Flutter app or engine.';
}
