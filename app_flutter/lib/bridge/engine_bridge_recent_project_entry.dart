part of 'engine_bridge.dart';

class RecentProjectEntry {
  const RecentProjectEntry({
    required this.uri,
    required this.name,
    required this.openedAt,
  });

  final String uri;
  final String name;
  final DateTime openedAt;

  factory RecentProjectEntry.fromMap(Map<dynamic, dynamic> map) =>
      RecentProjectEntry(
        uri: map['uri'] as String? ?? '',
        name: map['name'] as String? ?? 'Project',
        openedAt: DateTime.fromMillisecondsSinceEpoch(
          (map['openedAtMillis'] as num?)?.toInt() ?? 0,
        ),
      );
}
