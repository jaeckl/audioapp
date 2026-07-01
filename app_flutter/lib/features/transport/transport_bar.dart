import 'package:flutter/material.dart';

import '../../app/shell_insets.dart';
import '../arrangement/snap_grid_resolution.dart';
import 'transport_bar_theme.dart';
import 'transport_bpm_box.dart';
import 'transport_position_format.dart';

class _SnapGridMenu extends StatefulWidget {
  const _SnapGridMenu({
    required this.resolution,
    required this.triplet,
    required this.onResolutionChanged,
    required this.onTripletChanged,
  });

  final SnapGridResolution resolution;
  final bool triplet;
  final ValueChanged<SnapGridResolution> onResolutionChanged;
  final ValueChanged<bool> onTripletChanged;

  @override
  State<_SnapGridMenu> createState() => _SnapGridMenuState();
}

class _SnapGridMenuState extends State<_SnapGridMenu> {
  late SnapGridResolution _resolution = widget.resolution;
  late bool _triplet = widget.triplet;

  void _setResolution(SnapGridResolution resolution) {
    setState(() => _resolution = resolution);
    widget.onResolutionChanged(resolution);
  }

  void _setTriplet(bool triplet) {
    setState(() => _triplet = triplet);
    widget.onTripletChanged(triplet);
  }

  Widget _tile({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active ? const Color(0xFF4B4B68) : const Color(0xFF30303C),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolutions = SnapGridResolution.values.skip(1).toList();
    return SizedBox(
      width: 246,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: _tile(
              label: 'Adaptive',
              active: _resolution == SnapGridResolution.adaptive,
              onTap: () => _setResolution(SnapGridResolution.adaptive),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.9,
            children: [
              for (final resolution in resolutions)
                _tile(
                  label: resolution.label,
                  active: _resolution == resolution,
                  onTap: () => _setResolution(resolution),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _tile(
                  label: 'Straight',
                  active: !_triplet,
                  onTap: () => _setTriplet(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tile(
                  label: 'Triplets',
                  active: _triplet,
                  onTap: () => _setTriplet(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TransportBar extends StatelessWidget {
  const TransportBar({
    super.key,
    required this.bpm,
    required this.playheadBeats,
    required this.playing,
    required this.loopEnabled,
    required this.loopRegionStartBeat,
    required this.loopRegionEndBeat,
    required this.recordArmed,
    required this.followPlayheadEnabled,
    required this.followPlayheadSuspended,
    this.selectedTrackName,
    this.songEndBeat,
    this.onPlayRequested,
    this.onStopRequested,
    this.onJumpToStart,
    this.onBpmChanged,
    this.onLoopToggled,
    this.onFollowPlayheadToggled,
    this.onExportMix,
    this.snapGridResolution = SnapGridResolution.adaptive,
    this.snapGridTriplet = false,
    this.onSnapGridResolutionChanged,
    this.onSnapGridTripletChanged,
  });

  final int bpm;
  final double playheadBeats;
  final bool playing;
  final bool loopEnabled;
  final double loopRegionStartBeat;
  final double loopRegionEndBeat;
  final bool recordArmed;
  final bool followPlayheadEnabled;
  final bool followPlayheadSuspended;
  final String? selectedTrackName;
  final double? songEndBeat;
  final VoidCallback? onPlayRequested;
  final VoidCallback? onStopRequested;
  final VoidCallback? onJumpToStart;
  final ValueChanged<int>? onBpmChanged;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<bool>? onFollowPlayheadToggled;
  final VoidCallback? onExportMix;
  final SnapGridResolution snapGridResolution;
  final bool snapGridTriplet;
  final ValueChanged<SnapGridResolution>? onSnapGridResolutionChanged;
  final ValueChanged<bool>? onSnapGridTripletChanged;

  @override
  Widget build(BuildContext context) {
    final positionPrimary =
        TransportPositionFormat.playheadCompact(playheadBeats);
    final positionSecondary =
        TransportPositionFormat.elapsedClock(playheadBeats, bpm);
    final loopTooltip = loopEnabled
        ? 'Loop ${TransportPositionFormat.loopBarRange(loopRegionStartBeat, loopRegionEndBeat)} — tap to disable'
        : 'Loop off — tap to enable';
    final followTooltip = followPlayheadSuspended && followPlayheadEnabled
        ? 'Follow paused — tap to toggle'
        : (followPlayheadEnabled
            ? 'Follow on — tap to disable'
            : 'Follow off — tap to enable');

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: TransportBarTheme.background,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: SizedBox(
        height: TransportBarTheme.rowHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TransportBarTheme.barPaddingH,
            TransportBarTheme.barPaddingV,
            4,
            TransportBarTheme.barPaddingV,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PositionPanel(
                  playing: playing,
                  onPlay: onPlayRequested,
                  onStop: onStopRequested,
                  onJumpToStart: onJumpToStart,
                  positionPrimary: positionPrimary,
                  positionSecondary: positionSecondary,
                  loopEnabled: loopEnabled,
                  recordArmed: recordArmed,
                  followActive:
                      followPlayheadEnabled && !followPlayheadSuspended,
                  followEnabled: followPlayheadEnabled,
                  loopTooltip: loopTooltip,
                  followTooltip: followTooltip,
                  onLoopToggled: onLoopToggled,
                  onFollowPlayheadToggled: onFollowPlayheadToggled,
                ),
              ),
              SizedBox(width: TransportBarTheme.cardGap),
              TransportBpmBox(
                bpm: bpm,
                enabled: onBpmChanged != null,
                onChanged: onBpmChanged,
              ),
              PopupMenuButton<void>(
                tooltip:
                    'Snap grid: ${snapGridResolution.label}${snapGridTriplet ? ' triplet' : ''}',
                enabled: onSnapGridResolutionChanged != null,
                color: const Color(0xFF24242E),
                icon:
                    const Icon(Icons.grid_4x4, size: 20, color: Colors.white70),
                itemBuilder: (context) => [
                  PopupMenuItem<void>(
                    enabled: false,
                    padding: const EdgeInsets.all(10),
                    child: _SnapGridMenu(
                      resolution: snapGridResolution,
                      triplet: snapGridTriplet,
                      onResolutionChanged: (resolution) =>
                          onSnapGridResolutionChanged?.call(resolution),
                      onTripletChanged: (triplet) =>
                          onSnapGridTripletChanged?.call(triplet),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget padded({
    required BuildContext context,
    required int bpm,
    required double playheadBeats,
    required bool playing,
    required bool loopEnabled,
    required double loopRegionStartBeat,
    required double loopRegionEndBeat,
    required bool recordArmed,
    bool followPlayheadEnabled = true,
    bool followPlayheadSuspended = false,
    String? selectedTrackName,
    double? songEndBeat,
    VoidCallback? onPlayRequested,
    VoidCallback? onStopRequested,
    VoidCallback? onJumpToStart,
    ValueChanged<int>? onBpmChanged,
    ValueChanged<bool>? onLoopToggled,
    ValueChanged<bool>? onFollowPlayheadToggled,
    VoidCallback? onExportMix,
    SnapGridResolution snapGridResolution = SnapGridResolution.adaptive,
    bool snapGridTriplet = false,
    ValueChanged<SnapGridResolution>? onSnapGridResolutionChanged,
    ValueChanged<bool>? onSnapGridTripletChanged,
  }) {
    return Padding(
      padding: ShellInsets.headerPadding(context).copyWith(bottom: 1),
      child: TransportBar(
        bpm: bpm,
        playheadBeats: playheadBeats,
        playing: playing,
        loopEnabled: loopEnabled,
        loopRegionStartBeat: loopRegionStartBeat,
        loopRegionEndBeat: loopRegionEndBeat,
        recordArmed: recordArmed,
        followPlayheadEnabled: followPlayheadEnabled,
        followPlayheadSuspended: followPlayheadSuspended,
        selectedTrackName: selectedTrackName,
        songEndBeat: songEndBeat,
        onPlayRequested: onPlayRequested,
        onStopRequested: onStopRequested,
        onJumpToStart: onJumpToStart,
        onBpmChanged: onBpmChanged,
        onLoopToggled: onLoopToggled,
        onFollowPlayheadToggled: onFollowPlayheadToggled,
        onExportMix: onExportMix,
        snapGridResolution: snapGridResolution,
        snapGridTriplet: snapGridTriplet,
        onSnapGridResolutionChanged: onSnapGridResolutionChanged,
        onSnapGridTripletChanged: onSnapGridTripletChanged,
      ),
    );
  }
}

class _PositionPanel extends StatelessWidget {
  const _PositionPanel({
    required this.playing,
    required this.positionPrimary,
    required this.positionSecondary,
    required this.loopEnabled,
    required this.recordArmed,
    required this.followActive,
    required this.followEnabled,
    required this.loopTooltip,
    required this.followTooltip,
    this.onPlay,
    this.onStop,
    this.onJumpToStart,
    this.onLoopToggled,
    this.onFollowPlayheadToggled,
  });

  final bool playing;
  final String positionPrimary;
  final String positionSecondary;
  final bool loopEnabled;
  final bool recordArmed;
  final bool followActive;
  final bool followEnabled;
  final String loopTooltip;
  final String followTooltip;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;
  final VoidCallback? onJumpToStart;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<bool>? onFollowPlayheadToggled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TransportBarTheme.chipFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: TransportBarTheme.statusIconHit,
              child: _StatusIconColumn(
                loopEnabled: loopEnabled,
                recordArmed: recordArmed,
                followActive: followActive,
                followEnabled: followEnabled,
                loopTooltip: loopTooltip,
                followTooltip: followTooltip,
                onLoopToggled: onLoopToggled,
                onFollowPlayheadToggled: onFollowPlayheadToggled,
              ),
            ),
            Row(
              children: [
                _JumpToStartButton(onPressed: onJumpToStart),
                _InlinePlayStop(
                  playing: playing,
                  onPlay: onPlay,
                  onStop: onStop,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      TransportBarTheme.cardInnerPaddingH,
                      TransportBarTheme.cardInnerPaddingV,
                      TransportBarTheme.statusIconHit + 4,
                      TransportBarTheme.cardInnerPaddingV,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'POSITION',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: TransportBarTheme.textMuted,
                                    fontSize: 9,
                                    letterSpacing: 0.6,
                                  ),
                        ),
                        Row(
                          children: [
                            Text(
                              positionPrimary,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: TransportBarTheme.textPrimary,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              positionSecondary,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: TransportBarTheme.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpToStartButton extends StatelessWidget {
  const _JumpToStartButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Jump to start',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 32,
            height: double.infinity,
            child: Icon(
              Icons.skip_previous_rounded,
              color: onPressed == null
                  ? TransportBarTheme.textMuted
                  : TransportBarTheme.textSecondary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlinePlayStop extends StatelessWidget {
  const _InlinePlayStop({
    required this.playing,
    this.onPlay,
    this.onStop,
  });

  final bool playing;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final active = playing;
    return Semantics(
      button: true,
      label: active ? 'Stop' : 'Play',
      child: Material(
        color: active
            ? TransportBarTheme.accentPlay.withValues(alpha: 0.16)
            : Colors.transparent,
        child: InkWell(
          onTap: active ? onStop : onPlay,
          child: SizedBox(
            width: 40,
            height: double.infinity,
            child: Icon(
              active ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: active
                  ? TransportBarTheme.accentPlay
                  : TransportBarTheme.textPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIconColumn extends StatelessWidget {
  const _StatusIconColumn({
    required this.loopEnabled,
    required this.recordArmed,
    required this.followActive,
    required this.followEnabled,
    required this.loopTooltip,
    required this.followTooltip,
    this.onLoopToggled,
    this.onFollowPlayheadToggled,
  });

  final bool loopEnabled;
  final bool recordArmed;
  final bool followActive;
  final bool followEnabled;
  final String loopTooltip;
  final String followTooltip;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<bool>? onFollowPlayheadToggled;

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[
      _StatusIconButton(
        icon: loopEnabled ? Icons.loop : Icons.loop_outlined,
        tooltip: loopTooltip,
        accent: loopEnabled ? TransportBarTheme.accentLoop : null,
        onTap:
            onLoopToggled == null ? null : () => onLoopToggled!(!loopEnabled),
      ),
      if (recordArmed)
        const _StatusIconButton(
          icon: Icons.fiber_manual_record,
          tooltip: 'Record armed',
          accent: TransportBarTheme.accentRecord,
        ),
      _StatusIconButton(
        icon: followEnabled ? Icons.my_location : Icons.location_searching,
        tooltip: followTooltip,
        accent: followActive ? TransportBarTheme.accentPlay : null,
        onTap: onFollowPlayheadToggled == null
            ? null
            : () => onFollowPlayheadToggled!(!followEnabled),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final slot in slots) Expanded(child: slot)],
    );
  }
}

class _StatusIconButton extends StatelessWidget {
  const _StatusIconButton({
    required this.icon,
    required this.tooltip,
    this.accent,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? TransportBarTheme.textSecondary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent != null
            ? accent!.withValues(alpha: 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Icon(icon,
                size: TransportBarTheme.statusIconSize, color: color),
          ),
        ),
      ),
    );
  }
}
