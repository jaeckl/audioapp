import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

const double _pixelsPerBeat = 48;
const double _trackLaneHeight = 56;
const double _trackHeaderWidth = 120;
const double _timelineBeats = 16;

class ArrangementView extends StatelessWidget {
  const ArrangementView({
    super.key,
    required this.snapshot,
    required this.onTrackSelected,
    required this.onAddTrack,
    required this.onAddMidiClip,
    required this.playheadBeats,
    required this.onClipTap,
    required this.onSaveProject,
    required this.onLoadProject,
  });

  final ProjectSnapshot snapshot;
  final ValueChanged<String> onTrackSelected;
  final VoidCallback onAddTrack;
  final VoidCallback onAddMidiClip;
  final double playheadBeats;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;
  final VoidCallback onSaveProject;
  final VoidCallback onLoadProject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timelineWidth = _timelineBeats * _pixelsPerBeat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text('Arrangement', style: theme.textTheme.titleMedium),
              IconButton(
                tooltip: 'Save project',
                onPressed: onSaveProject,
                icon: const Icon(Icons.save_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Load project',
                onPressed: onLoadProject,
                icon: const Icon(Icons.folder_open_outlined, size: 20),
              ),
              const Spacer(),
              if (snapshot.selectedTrack != null)
                FilledButton.tonalIcon(
                  onPressed: onAddMidiClip,
                  icon: const Icon(Icons.piano, size: 18),
                  label: const Text('Clip'),
                ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onAddTrack,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Track'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: snapshot.tracks.isEmpty
                ? Center(
                    child: Text(
                      'No tracks — tap Track to add one',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: _trackHeaderWidth,
                                child: Column(
                                  children: [
                                    for (final track in snapshot.tracks)
                                      _TrackHeader(
                                        track: track,
                                        selected: track.id == snapshot.selectedTrackId,
                                        onTap: () => onTrackSelected(track.id),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: timelineWidth,
                                    child: Stack(
                                      children: [
                                        Column(
                                          children: [
                                            for (final track in snapshot.tracks)
                                              _TrackLane(
                                                track: track,
                                                selected: track.id == snapshot.selectedTrackId,
                                                onClipTap: onClipTap,
                                              ),
                                          ],
                                        ),
                                        Positioned(
                                          left: playheadBeats * _pixelsPerBeat,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 2,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({
    required this.track,
    required this.selected,
    required this.onTap,
  });

  final TrackSnapshot track;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? const Color(0xFF2D2D3A) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _trackLaneHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Text(
            track.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? theme.colorScheme.primary : Colors.white,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackLane extends StatelessWidget {
  const _TrackLane({
    required this.track,
    required this.selected,
    required this.onClipTap,
  });

  final TrackSnapshot track;
  final bool selected;
  final void Function(String trackId, MidiClipSnapshot clip) onClipTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _trackLaneHeight,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF22222C) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final clip in track.midiClips)
            Positioned(
              left: clip.startBeat * _pixelsPerBeat,
              top: 8,
              width: clip.lengthBeats * _pixelsPerBeat,
              height: _trackLaneHeight - 16,
              child: _MidiClipBlock(
                clip: clip,
                onTap: () => onClipTap(track.id, clip),
              ),
            ),
        ],
      ),
    );
  }
}

class _MidiClipBlock extends StatelessWidget {
  const _MidiClipBlock({required this.clip, required this.onTap});

  final MidiClipSnapshot clip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF3A4A6B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            'MIDI',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
