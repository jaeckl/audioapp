part of 'sample_editor_take_panel.dart';

class SampleEditorTakeToolsPanel extends StatelessWidget {
  const SampleEditorTakeToolsPanel({
    super.key,
    required this.playheadBeat,
    required this.selectedMarkerBeat,
    required this.onSplitAtPlayhead,
    required this.onDeleteSelected,
    required this.onNudgeSelected,
    this.selectedMarkerHold,
    this.onMarkerModeChanged,
    this.enabled = true,
  });

  /// When false the comp editing controls are frozen (e.g. a flattened MIDI
  /// comp, where the derived notes are no longer authoritative).
  final bool enabled;

  final double playheadBeat;
  final double? selectedMarkerBeat;
  final VoidCallback onSplitAtPlayhead;
  final VoidCallback onDeleteSelected;
  final ValueChanged<int> onNudgeSelected;

  /// MIDI-only: current boundary handoff of the selected marker (true = ring,
  /// false = cut). When [onMarkerModeChanged] is null the toggle is hidden
  /// (e.g. the sample editor, where audio crossfades naturally).
  final bool? selectedMarkerHold;
  final ValueChanged<bool>? onMarkerModeChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('COMPING',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .7)),
                      const SizedBox(height: 3),
                      Text(
                          enabled
                              ? 'Edit comp markers, then tap take lane for segment.'
                              : 'Comp flattened — re-open to edit markers.',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  _BeatBadge(label: '${playheadBeat.toStringAsFixed(2)}b'),
                ]),
                const SizedBox(height: 12),
                IgnorePointer(
                  ignoring: !enabled,
                  child: Opacity(
                    opacity: enabled ? 1 : 0.4,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _TakeSplitButton(
                          beatLabel: '${playheadBeat.toStringAsFixed(2)}b',
                          onTap: onSplitAtPlayhead,
                        ),
                        _SelectedMarkerTile(beat: selectedMarkerBeat),
                        _SmallTakeButton(
                          icon: Icons.chevron_left,
                          label: 'NUDGE -',
                          enabled: selectedMarkerBeat != null,
                          onTap: () => onNudgeSelected(-1),
                        ),
                        _SmallTakeButton(
                          icon: Icons.chevron_right,
                          label: 'NUDGE +',
                          enabled: selectedMarkerBeat != null,
                          onTap: () => onNudgeSelected(1),
                        ),
                        _SmallTakeButton(
                          icon: Icons.delete_outline,
                          label: 'DELETE',
                          enabled: selectedMarkerBeat != null,
                          onTap: onDeleteSelected,
                        ),
                        if (onMarkerModeChanged != null)
                          _BoundaryModeTile(
                            hold: selectedMarkerHold ?? true,
                            enabled: selectedMarkerBeat != null,
                            onChanged: onMarkerModeChanged!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
