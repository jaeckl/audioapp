import 'dart:collection';

import '../../bridge/engine_bridge.dart';

/// LRU cache for ClipPreviewData, capped at 50 entries.
/// Cleared on library close (session lifetime).
class ClipPreviewCache {
  static const int kMaxCacheEntries = 50;

  final _LinkedHashMap<String, ClipPreviewData> _cache = _LinkedHashMap();

  ClipPreviewData? get(String key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // move to end (most recently used)
    }
    return value;
  }

  void put(String key, ClipPreviewData value) {
    _cache.remove(key);
    if (_cache.length >= kMaxCacheEntries) {
      _cache.remove(_cache.keys.first); // evict oldest (LRU)
    }
    _cache[key] = value;
  }

  void remove(String key) => _cache.remove(key);

  void clear() => _cache.clear();

  int get length => _cache.length;

  bool containsKey(String key) => _cache.containsKey(key);
}

/// Simple linked-hash-map that preserves insertion order.
/// Dart's LinkedHashMap does this by default.
typedef _LinkedHashMap<K, V> = LinkedHashMap<K, V>;