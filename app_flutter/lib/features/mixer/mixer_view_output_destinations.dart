part of 'mixer_view.dart';

class _OutputDestination {
  const _OutputDestination({required this.id, required this.label});
  final String id;
  final String label;
}

List<_OutputDestination> _outputChoicesFor({
  required ProjectSnapshot snapshot,
  required String selfId,
}) {
  return [
    const _OutputDestination(id: 'master', label: 'Master'),
    const _OutputDestination(id: 'device', label: 'Device'),
    for (final track in snapshot.tracks)
      if (track.id != selfId)
        _OutputDestination(id: track.id, label: track.name),
  ];
}
