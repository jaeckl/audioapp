import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'play_deck_theme.dart';

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

class _TrackChip extends StatelessWidget {
  const _TrackChip({
    required this.name,
    required this.selected,
    required this.muted,
    required this.soloed,
    required this.onSelect,
    required this.onMute,
    required this.onSolo,
  });

  final String name;
  final bool selected;
  final bool muted;
  final bool soloed;
  final VoidCallback onSelect;
  final VoidCallback onMute;
  final VoidCallback onSolo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2D2D3A) : PlayDeckTheme.optionIdle,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  color: PlayDeckTheme.optionLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              _MiniButton(label: 'M', active: muted, onTap: onMute, color: Colors.redAccent),
              const SizedBox(width: 4),
              _MiniButton(label: 'S', active: soloed, onTap: onSolo, color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.color,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? color : const Color(0xFF1C1C20),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? Colors.black : PlayDeckTheme.optionLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
