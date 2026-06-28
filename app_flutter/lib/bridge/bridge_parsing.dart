/// Shared parsing helpers for native bridge JSON maps.
library;

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