part of 'mixer_view.dart';

class _OutputDestination {
  const _OutputDestination({
    required this.id,
    required this.label,
    required this.icon,
  });
  final String id;
  final String label;
  final IconData icon;
}

List<_OutputDestination> _outputChoicesFor({
  required ProjectSnapshot snapshot,
  required String selfId,
}) {
  return [
    const _OutputDestination(
      id: 'master',
      label: 'Master',
      icon: Icons.speaker_outlined,
    ),
    const _OutputDestination(
      id: 'device',
      label: 'Device',
      icon: Icons.headphones_outlined,
    ),
    for (var i = 0; i < snapshot.tracks.length; i++)
      if (snapshot.tracks[i].id != selfId)
        _OutputDestination(
          id: snapshot.tracks[i].id,
          label: snapshot.tracks[i].name,
          icon: TrackLaneIcon.iconForTrack(snapshot.tracks[i], i),
        ),
  ];
}

_OutputDestination? _choiceById(
  List<_OutputDestination> choices,
  String id,
) {
  for (final choice in choices) {
    if (choice.id == id) return choice;
  }
  return null;
}
