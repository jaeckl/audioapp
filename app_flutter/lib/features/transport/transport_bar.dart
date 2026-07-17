import 'package:flutter/material.dart';

import '../../app/shell_insets.dart';
import '../arrangement/snap_grid_resolution.dart';
import 'transport_bar_theme.dart';
import 'transport_bpm_box.dart';
import 'transport_position_format.dart';

part 'inline_metronome_button.dart';
part 'inline_play_stop.dart';
part 'jump_to_start_button.dart';
part 'metronome_menu.dart';
part 'metronome_menu_state.dart';
part 'position_panel.dart';
part 'snap_grid_menu.dart';
part 'snap_grid_menu_button.dart';
part 'snap_grid_menu_state.dart';
part 'snap_grid_section_title.dart';
part 'status_icon_button.dart';
part 'status_icon_column.dart';

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
      key: const ValueKey('transport-chrome'),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TransportBarTheme.background,
        borderRadius: BorderRadius.circular(TransportBarTheme.panelRadius),
        border: Border.all(color: TransportBarTheme.panelBorder),
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
              const SizedBox(width: TransportBarTheme.cardGap),
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
