part of 'play_deck.dart';

extension PlayDeckStateBuildchordpitchesOperation on PlayDeckState {
static List<int> _buildChordPitches(int root, ChordQuality q, int span) {
    final intervals = q.intervals;
    return [
      for (var o = 0; o < span; o++)
        for (final step in intervals) root + o * 12 + step,
    ];
  }
}
