part of 'engine_bridge.dart';

extension EngineBridgeGetrecentprojectsOperation on EngineBridge {
  Future<List<RecentProjectEntry>> getRecentProjects() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('getRecentProjects');
    if (result == null || result['ok'] != true) return const [];
    final projects = result['projects'] as List<dynamic>? ?? const [];
    return projects
        .map(
            (item) => RecentProjectEntry.fromMap(item as Map<dynamic, dynamic>))
        .where((item) => item.uri.isNotEmpty)
        .toList();
  }
}
