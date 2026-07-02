import 'piano_roll_metrics.dart';

class MidiLaneDefinition {
  const MidiLaneDefinition({
    required this.pitch,
    required this.name,
    this.enabled = true,
  });

  final int pitch;
  final String name;
  final bool enabled;
}

class MidiLaneLayout {
  MidiLaneLayout(Iterable<MidiLaneDefinition> source, {int minimumRows = 8})
      : lanes = _withGhostRows(source, minimumRows);

  final List<MidiLaneDefinition> lanes;

  bool get isNotEmpty => lanes.any((lane) => lane.enabled);

  static List<MidiLaneDefinition> _withGhostRows(
    Iterable<MidiLaneDefinition> source,
    int minimumRows,
  ) {
    final result = source.toList()..sort((a, b) => b.pitch.compareTo(a.pitch));
    if (result.isEmpty) return result;
    final used = result.map((lane) => lane.pitch).toSet();
    var candidate = result.last.pitch - 1;
    while (result.length < minimumRows && candidate >= 0) {
      if (used.add(candidate)) {
        result.add(MidiLaneDefinition(
          pitch: candidate,
          name: '',
          enabled: false,
        ));
      }
      candidate--;
    }
    candidate = result.first.pitch + 1;
    while (result.length < minimumRows && candidate <= 127) {
      if (used.add(candidate)) {
        result.add(MidiLaneDefinition(
          pitch: candidate,
          name: '',
          enabled: false,
        ));
      }
      candidate++;
    }
    return result;
  }

  static String defaultName(int pitch) => PianoRollMetrics.noteLabel(pitch);
}

enum MidiEditorMode { piano, drums }
