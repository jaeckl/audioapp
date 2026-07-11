import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'play_deck_theme.dart';

part 'track_mute_row_track_chip.dart';
part 'track_mute_row_mini_button.dart';

class TrackMuteRow extends StatelessWidget {
  const TrackMuteRow({
    super.key,
    required this.tracks,
    required this.selectedTrackId,
    required this.mutedTrackIds,
    required this.soloedTrackIds,
    required this.onToggleMute,
    required this.onToggleSolo,
    required this.onSelectTrack,
  });

  final List<TrackSnapshot> tracks;
  final String selectedTrackId;
  final Set<String> mutedTrackIds;
  final Set<String> soloedTrackIds;
  final ValueChanged<String> onToggleMute;
  final ValueChanged<String> onToggleSolo;
  final ValueChanged<String> onSelectTrack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ColoredBox(
        color: PlayDeckTheme.stripBackground,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemCount: tracks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final track = tracks[index];
            final selected = track.id == selectedTrackId;
            final muted = mutedTrackIds.contains(track.id);
            final soloed = soloedTrackIds.contains(track.id);
            return _TrackChip(
              name: track.name,
              selected: selected,
              muted: muted,
              soloed: soloed,
              onSelect: () => onSelectTrack(track.id),
              onMute: () => onToggleMute(track.id),
              onSolo: () => onToggleSolo(track.id),
            );
          },
        ),
      ),
    );
  }
}
