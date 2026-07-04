import 'package:flutter/material.dart';

import '../../app/shell_insets.dart';
import '../arrangement/snap_grid_resolution.dart';
import 'transport_bar_theme.dart';
import 'transport_bpm_box.dart';
import 'transport_position_format.dart';

class _SnapGridMenu extends StatefulWidget {
  const _SnapGridMenu({
    required this.snapClips,
    required this.resolution,
    required this.triplet,
    required this.onSnapClipsChanged,
    required this.onResolutionChanged,
    required this.onTripletChanged,
  });

  final bool snapClips;
  final SnapGridResolution resolution;
  final bool triplet;
  final ValueChanged<bool> onSnapClipsChanged;
  final ValueChanged<SnapGridResolution> onResolutionChanged;
  final ValueChanged<bool> onTripletChanged;

  @override
  State<_SnapGridMenu> createState() => _SnapGridMenuState();
}

class _SnapGridMenuState extends State<_SnapGridMenu> {
  late bool _snapClips = widget.snapClips;
  late SnapGridResolution _resolution = widget.resolution;
  late bool _triplet = widget.triplet;

  void _setSnapClips(bool enabled) {
    setState(() => _snapClips = enabled);
    widget.onSnapClipsChanged(enabled);
  }

  void _setResolution(SnapGridResolution resolution) {
    setState(() => _resolution = resolution);
    widget.onResolutionChanged(resolution);
  }

  void _setTriplet(bool triplet) {
    setState(() => _triplet = triplet);
    widget.onTripletChanged(triplet);
  }

  Widget _pill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active
          ? TransportBarTheme.menuPillActiveFill
          : TransportBarTheme.menuPillIdle,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active
                  ? TransportBarTheme.menuPillActiveText
                  : TransportBarTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Grid',
            style: TextStyle(
              color: TransportBarTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const _SnapGridSectionTitle('Clip snap'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _pill(
                  label: 'Off',
                  active: !_snapClips,
                  onTap: () => _setSnapClips(false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _pill(
                  label: 'On',
                  active: _snapClips,
                  onTap: () => _setSnapClips(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SnapGridSectionTitle('Resolution'),
          const SizedBox(height: 8),
          _pill(
            label: 'Adaptive',
            active: _resolution == SnapGridResolution.adaptive,
            onTap: () => _setResolution(SnapGridResolution.adaptive),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final resolution in resolutions)
                _pill(
                  label: resolution.label,
                  active: _resolution == resolution,
                  onTap: () => _setResolution(resolution),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const _SnapGridSectionTitle('Triplet'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _pill(
                  label: 'Straight',
                  active: !_triplet,
                  onTap: () => _setTriplet(false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _pill(
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

class _SnapGridSectionTitle extends StatelessWidget {
  const _SnapGridSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: TransportBarTheme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _SnapGridMenuButton extends StatelessWidget {
  const _SnapGridMenuButton({
    required this.snapClipsEnabled,
    required this.snapGridResolution,
    required this.snapGridTriplet,
    required this.enabled,
    this.onSnapClipsEnabledChanged,
    this.onSnapGridResolutionChanged,
    this.onSnapGridTripletChanged,
  });

  final bool snapClipsEnabled;
  final SnapGridResolution snapGridResolution;
  final bool snapGridTriplet;
  final bool enabled;
  final ValueChanged<bool>? onSnapClipsEnabledChanged;
  final ValueChanged<SnapGridResolution>? onSnapGridResolutionChanged;
  final ValueChanged<bool>? onSnapGridTripletChanged;

  @override
  Widget build(BuildContext context) {
    final tooltip =
        '${snapClipsEnabled ? 'Clip snap on' : 'Clip snap off'} · ${snapGridResolution.label}${snapGridTriplet ? ' triplet' : ''}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: TransportBarTheme.chipFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<void>(
        tooltip: tooltip,
        enabled: enabled,
        padding: EdgeInsets.zero,
        color: TransportBarTheme.menuBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: TransportBarTheme.chipBorder),
        ),
        icon: Icon(
          Icons.grid_4x4,
          size: 20,
          color: enabled
              ? TransportBarTheme.textSecondary
              : TransportBarTheme.textMuted,
        ),
        itemBuilder: (context) => [
          PopupMenuItem<void>(
            enabled: false,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: _SnapGridMenu(
              snapClips: snapClipsEnabled,
              resolution: snapGridResolution,
              triplet: snapGridTriplet,
              onSnapClipsChanged: (value) =>
                  onSnapClipsEnabledChanged?.call(value),
              onResolutionChanged: (value) =>
                  onSnapGridResolutionChanged?.call(value),
              onTripletChanged: (value) =>
                  onSnapGridTripletChanged?.call(value),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetronomeMenu extends StatefulWidget {
  const _MetronomeMenu(
      {required this.enabled,
      required this.level,
      required this.countInBars,
      required this.onChanged});
  final bool enabled;
  final double level;
  final int countInBars;
  final void Function(bool enabled, double level, int countInBars) onChanged;
  @override
  State<_MetronomeMenu> createState() => _MetronomeMenuState();
}

class _MetronomeMenuState extends State<_MetronomeMenu> {
  late bool enabled = widget.enabled;
  late double level = widget.level;
  late int countInBars = widget.countInBars;
  void commit() => widget.onChanged(enabled, level, countInBars);
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 250,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Metronome',
                      style: TextStyle(
                          color: TransportBarTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600))),
              Switch(
                  value: enabled,
                  onChanged: (v) {
                    setState(() => enabled = v);
                    commit();
                  })
            ]),
            const SizedBox(height: 8),
            const _SnapGridSectionTitle('Click level'),
            Slider(
                value: level,
                min: 0,
                max: 1,
                onChanged: (v) {
                  setState(() => level = v);
                  commit();
                }),
            const _SnapGridSectionTitle('Count-in'),
            const SizedBox(height: 8),
            Row(children: [
              for (final bars in const [0, 1, 2, 4])
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Material(
                            color: countInBars == bars
                                ? TransportBarTheme.menuPillActiveFill
                                : TransportBarTheme.menuPillIdle,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                                onTap: () {
                                  setState(() => countInBars = bars);
                                  commit();
                                },
                                child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(bars == 0 ? 'Off' : '$bars',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: countInBars == bars
                                                ? TransportBarTheme
                                                    .menuPillActiveText
                                                : TransportBarTheme
                                                    .textSecondary)))))))
            ])
          ]));
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
    this.recordingActive = false,
    this.recordingStartBeat = 0,
    this.recordingInputLevel = 0,
    this.recordingModeLabel,
    required this.followPlayheadEnabled,
    required this.followPlayheadSuspended,
    this.selectedTrackName,
    this.songEndBeat,
    this.onPlayRequested,
    this.onStopRequested,
    this.onJumpToStart,
    this.onBpmChanged,
    this.onLoopToggled,
    this.onRecordArmedChanged,
    this.onCancelRecording,
    this.onFollowPlayheadToggled,
    this.onExportMix,
    this.snapClipsEnabled = true,
    this.snapGridResolution = SnapGridResolution.adaptive,
    this.snapGridTriplet = false,
    this.onSnapClipsEnabledChanged,
    this.onSnapGridResolutionChanged,
    this.onSnapGridTripletChanged,
    this.metronomeEnabled = false,
    this.metronomeLevel = 0.65,
    this.countInBars = 1,
    this.onMetronomeChanged,
  });

  final int bpm;
  final double playheadBeats;
  final bool playing;
  final bool loopEnabled;
  final double loopRegionStartBeat;
  final double loopRegionEndBeat;
  final bool recordArmed;
  final bool recordingActive;
  final double recordingStartBeat;
  final double recordingInputLevel;
  final String? recordingModeLabel;
  final bool followPlayheadEnabled;
  final bool followPlayheadSuspended;
  final String? selectedTrackName;
  final double? songEndBeat;
  final VoidCallback? onPlayRequested;
  final VoidCallback? onStopRequested;
  final VoidCallback? onJumpToStart;
  final ValueChanged<int>? onBpmChanged;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<bool>? onRecordArmedChanged;
  final VoidCallback? onCancelRecording;
  final ValueChanged<bool>? onFollowPlayheadToggled;
  final VoidCallback? onExportMix;
  final bool snapClipsEnabled;
  final SnapGridResolution snapGridResolution;
  final bool snapGridTriplet;
  final ValueChanged<bool>? onSnapClipsEnabledChanged;
  final ValueChanged<SnapGridResolution>? onSnapGridResolutionChanged;
  final ValueChanged<bool>? onSnapGridTripletChanged;
  final bool metronomeEnabled;
  final double metronomeLevel;
  final int countInBars;
  final void Function(bool enabled, double level, int countInBars)?
      onMetronomeChanged;

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
                  recordingTrackName: selectedTrackName,
                  recordingInputLevel: recordingInputLevel,
                  metronomeEnabled: metronomeEnabled,
                  metronomeLevel: metronomeLevel,
                  countInBars: countInBars,
                  loopEnabled: loopEnabled,
                  recordArmed: recordArmed,
                  recordingActive: recordingActive,
                  recordingModeLabel: recordingModeLabel,
                  followActive:
                      followPlayheadEnabled && !followPlayheadSuspended,
                  followEnabled: followPlayheadEnabled,
                  loopTooltip: loopTooltip,
                  followTooltip: followTooltip,
                  onLoopToggled: onLoopToggled,
                  onRecordArmedChanged: onRecordArmedChanged,
                  onCancelRecording: onCancelRecording,
                  onFollowPlayheadToggled: onFollowPlayheadToggled,
                  onMetronomeChanged: onMetronomeChanged,
                ),
              ),
              const SizedBox(width: TransportBarTheme.cardGap),
              TransportBpmBox(
                bpm: bpm,
                enabled: onBpmChanged != null,
                onChanged: onBpmChanged,
              ),
              _SnapGridMenuButton(
                snapClipsEnabled: snapClipsEnabled,
                snapGridResolution: snapGridResolution,
                snapGridTriplet: snapGridTriplet,
                enabled: onSnapGridResolutionChanged != null,
                onSnapClipsEnabledChanged: onSnapClipsEnabledChanged,
                onSnapGridResolutionChanged: onSnapGridResolutionChanged,
                onSnapGridTripletChanged: onSnapGridTripletChanged,
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
    bool recordingActive = false,
    double recordingStartBeat = 0,
    double recordingInputLevel = 0,
    String? recordingModeLabel,
    bool followPlayheadEnabled = true,
    bool followPlayheadSuspended = false,
    String? selectedTrackName,
    double? songEndBeat,
    VoidCallback? onPlayRequested,
    VoidCallback? onStopRequested,
    VoidCallback? onJumpToStart,
    ValueChanged<int>? onBpmChanged,
    ValueChanged<bool>? onLoopToggled,
    ValueChanged<bool>? onRecordArmedChanged,
    VoidCallback? onCancelRecording,
    ValueChanged<bool>? onFollowPlayheadToggled,
    VoidCallback? onExportMix,
    bool snapClipsEnabled = true,
    SnapGridResolution snapGridResolution = SnapGridResolution.adaptive,
    bool snapGridTriplet = false,
    ValueChanged<bool>? onSnapClipsEnabledChanged,
    ValueChanged<SnapGridResolution>? onSnapGridResolutionChanged,
    ValueChanged<bool>? onSnapGridTripletChanged,
    bool metronomeEnabled = false,
    double metronomeLevel = 0.65,
    int countInBars = 1,
    void Function(bool enabled, double level, int countInBars)?
        onMetronomeChanged,
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
        recordingActive: recordingActive,
        recordingStartBeat: recordingStartBeat,
        recordingInputLevel: recordingInputLevel,
        recordingModeLabel: recordingModeLabel,
        followPlayheadEnabled: followPlayheadEnabled,
        followPlayheadSuspended: followPlayheadSuspended,
        selectedTrackName: selectedTrackName,
        songEndBeat: songEndBeat,
        onPlayRequested: onPlayRequested,
        onStopRequested: onStopRequested,
        onJumpToStart: onJumpToStart,
        onBpmChanged: onBpmChanged,
        onLoopToggled: onLoopToggled,
        onRecordArmedChanged: onRecordArmedChanged,
        onCancelRecording: onCancelRecording,
        onFollowPlayheadToggled: onFollowPlayheadToggled,
        onExportMix: onExportMix,
        snapClipsEnabled: snapClipsEnabled,
        snapGridResolution: snapGridResolution,
        snapGridTriplet: snapGridTriplet,
        onSnapClipsEnabledChanged: onSnapClipsEnabledChanged,
        onSnapGridResolutionChanged: onSnapGridResolutionChanged,
        onSnapGridTripletChanged: onSnapGridTripletChanged,
        metronomeEnabled: metronomeEnabled,
        metronomeLevel: metronomeLevel,
        countInBars: countInBars,
        onMetronomeChanged: onMetronomeChanged,
      ),
    );
  }
}

class _PositionPanel extends StatelessWidget {
  const _PositionPanel({
    required this.playing,
    required this.positionPrimary,
    required this.positionSecondary,
    this.recordingTrackName,
    this.recordingInputLevel = 0,
    required this.metronomeEnabled,
    required this.metronomeLevel,
    required this.countInBars,
    required this.loopEnabled,
    required this.recordArmed,
    required this.recordingActive,
    this.recordingModeLabel,
    required this.followActive,
    required this.followEnabled,
    required this.loopTooltip,
    required this.followTooltip,
    this.onPlay,
    this.onStop,
    this.onJumpToStart,
    this.onLoopToggled,
    this.onRecordArmedChanged,
    this.onCancelRecording,
    this.onFollowPlayheadToggled,
    this.onMetronomeChanged,
  });

  final bool playing;
  final String positionPrimary;
  final String positionSecondary;
  final String? recordingTrackName;
  final double recordingInputLevel;
  final bool metronomeEnabled;
  final double metronomeLevel;
  final int countInBars;
  final bool loopEnabled;
  final bool recordArmed;
  final bool recordingActive;
  final String? recordingModeLabel;
  final bool followActive;
  final bool followEnabled;
  final String loopTooltip;
  final String followTooltip;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;
  final VoidCallback? onJumpToStart;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<bool>? onRecordArmedChanged;
  final VoidCallback? onCancelRecording;
  final ValueChanged<bool>? onFollowPlayheadToggled;
  final void Function(bool, double, int)? onMetronomeChanged;

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
                recordingActive: recordingActive,
                followActive: followActive,
                followEnabled: followEnabled,
                loopTooltip: loopTooltip,
                followTooltip: followTooltip,
                onLoopToggled: onLoopToggled,
                onRecordArmedChanged: onRecordArmedChanged,
                onCancelRecording: onCancelRecording,
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
                _InlineMetronomeButton(
                  enabled: metronomeEnabled,
                  level: metronomeLevel,
                  countInBars: countInBars,
                  onChanged: onMetronomeChanged,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
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
                              recordingActive
                                  ? (recordingModeLabel ??
                                      recordingTrackName ??
                                      'REC')
                                  : positionSecondary,
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
                        if (recordingActive) ...[
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              value: recordingInputLevel.clamp(0.0, 1.0),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                TransportBarTheme.accentRecord,
                              ),
                            ),
                          ),
                        ],
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

class _InlineMetronomeButton extends StatelessWidget {
  const _InlineMetronomeButton({
    required this.enabled,
    required this.level,
    required this.countInBars,
    this.onChanged,
  });

  final bool enabled;
  final double level;
  final int countInBars;
  final void Function(bool, double, int)? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: double.infinity,
      child: PopupMenuButton<void>(
        tooltip: enabled ? 'Metronome on' : 'Metronome off',
        enabled: onChanged != null,
        padding: EdgeInsets.zero,
        color: TransportBarTheme.menuBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: TransportBarTheme.chipBorder),
        ),
        icon: Icon(
          enabled ? Icons.timer : Icons.timer_outlined,
          size: 19,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : TransportBarTheme.textSecondary,
        ),
        itemBuilder: (_) => [
          PopupMenuItem<void>(
            enabled: false,
            padding: const EdgeInsets.all(14),
            child: _MetronomeMenu(
              enabled: enabled,
              level: level,
              countInBars: countInBars,
              onChanged: onChanged ?? (_, __, ___) {},
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIconColumn extends StatelessWidget {
  const _StatusIconColumn({
    required this.loopEnabled,
    required this.recordArmed,
    required this.recordingActive,
    required this.followActive,
    required this.followEnabled,
    required this.loopTooltip,
    required this.followTooltip,
    this.onLoopToggled,
    this.onRecordArmedChanged,
    this.onCancelRecording,
    this.onFollowPlayheadToggled,
  });

  final bool loopEnabled;
  final bool recordArmed;
  final bool recordingActive;
  final bool followActive;
  final bool followEnabled;
  final String loopTooltip;
  final String followTooltip;
  final ValueChanged<bool>? onLoopToggled;
  final ValueChanged<bool>? onRecordArmedChanged;
  final VoidCallback? onCancelRecording;
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
      _StatusIconButton(
        icon: recordingActive
            ? Icons.cancel_rounded
            : recordArmed
                ? Icons.fiber_manual_record
                : Icons.radio_button_unchecked,
        tooltip: recordingActive
            ? 'Cancel recording'
            : recordArmed
                ? 'Record armed — tap to disarm'
                : 'Arm selected track',
        accent: recordArmed || recordingActive
            ? TransportBarTheme.accentRecord
            : null,
        onTap: recordingActive
            ? onCancelRecording
            : onRecordArmedChanged == null
                ? null
                : () => onRecordArmedChanged!(!recordArmed),
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
