part of 'piano_roll_grid_sheet.dart';

class _PianoRollGridSheetState extends State<PianoRollGridSheet> {
  late PianoRollGridSettings _settings = widget.initialSettings;
  late PianoRollScaleSettings _scale = widget.initialScaleSettings;
  late PianoRollDrawPattern _drawPattern = widget.initialDrawPattern;
  late int _viewRangeBars = widget.initialViewRangeBars;

  void _setGrid(PianoRollGridSettings value) {
    setState(() => _settings = value);
    widget.onChanged(value);
  }

  void _setScale(PianoRollScaleSettings value) {
    setState(() => _scale = value);
    widget.onScaleChanged(value);
  }

  @override
  Widget build(BuildContext context) =>
      widget.drawControls ? _drawPanel() : _gridPanel();

  Widget _gridPanel() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Title(widget.showViewRange ? 'View' : 'Grid'),
          if (widget.showViewRange) ...[
            const SizedBox(height: 12),
            const _SectionTitle('Visible range'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final bars in EditorViewRange.bars)
                  _Pill(
                    label: '$bars bar${bars == 1 ? '' : 's'}',
                    active: _viewRangeBars == bars,
                    onTap: () {
                      setState(() => _viewRangeBars = bars);
                      widget.onViewRangeChanged?.call(bars);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFF343442)),
          ],
          const SizedBox(height: 12),
          const _SectionTitle('Note snap'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _Pill(
                label: 'Off',
                active: _settings.snap == PianoRollSnap.off,
                onTap: () => _setGrid(
                  _settings.copyWith(snap: PianoRollSnap.off),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _Pill(
                label: 'On',
                active: _settings.snap != PianoRollSnap.off,
                onTap: () => _setGrid(
                  _settings.copyWith(snap: PianoRollSnap.sixteenth),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _DropdownRow<PianoRollSnap>(
            label: 'Resolution',
            value: _settings.snap == PianoRollSnap.off
                ? PianoRollSnap.sixteenth
                : _settings.snap,
            values: PianoRollSnap.values
                .where((value) => value != PianoRollSnap.off)
                .toList(),
            text: (value) => value.shortLabel,
            onChanged: (value) => _setGrid(_settings.copyWith(snap: value)),
          ),
          const SizedBox(height: 12),
          _DropdownRow<double>(
            label: 'Note length',
            value: _noteLengthValue,
            values: const [0.125, 0.25, 0.5, 1, 2, 4, 8],
            text: _noteLengthLabel,
            onChanged: (value) =>
                _setGrid(_settings.copyWith(defaultNoteBeats: value)),
          ),
          const SizedBox(height: 12),
          const _SectionTitle('Grid feel'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _Pill(
                label: 'Straight',
                active: !_settings.triplet,
                onTap: () => _setGrid(_settings.copyWith(triplet: false)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _Pill(
                label: 'Triplets',
                active: _settings.triplet,
                onTap: () => _setGrid(_settings.copyWith(triplet: true)),
              ),
            ),
          ]),
          if (widget.showScaleControls) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFF343442)),
            const SizedBox(height: 12),
            const _SectionTitle('Scale'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: _DropdownRow<int>(
                  label: 'Root',
                  value: _scale.rootPitchClass,
                  values: List.generate(12, (index) => index),
                  text: (value) => PlayScale.noteNames[value],
                  onChanged: (value) =>
                      _setScale(_scale.copyWith(rootPitchClass: value)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DropdownRow<PlayScale>(
                  label: 'Type',
                  value: _scale.scale,
                  values: PlayScale.presets,
                  text: (value) => value.label,
                  onChanged: (value) =>
                      _setScale(_scale.copyWith(scale: value)),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _Pill(
                  label: 'Highlight',
                  active: _scale.highlight,
                  onTap: () =>
                      _setScale(_scale.copyWith(highlight: !_scale.highlight)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _Pill(
                  label: 'Snap pitch',
                  active: _scale.snapToScale,
                  onTap: () => _setScale(
                    _scale.copyWith(snapToScale: !_scale.snapToScale),
                  ),
                ),
              ),
            ]),
          ],
        ],
      );

  Widget _drawPanel() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Title('Draw settings'),
          const SizedBox(height: 12),
          _DropdownRow<double>(
            label: 'Note length',
            value: _noteLengthValue,
            values: const [0.125, 0.25, 0.5, 1, 2, 4, 8],
            text: _noteLengthLabel,
            onChanged: (value) =>
                _setGrid(_settings.copyWith(defaultNoteBeats: value)),
          ),
          if (widget.showScaleControls) ...[
            const SizedBox(height: 12),
            _DropdownRow<ChordQuality>(
              label: 'Chord mode',
              value: _scale.chordQuality,
              values: ChordQuality.values,
              text: (value) =>
                  value == ChordQuality.off ? 'Single note' : value.label,
              onChanged: (value) =>
                  _setScale(_scale.copyWith(chordQuality: value)),
            ),
          ],
          const SizedBox(height: 12),
          _DropdownRow<PianoRollDrawPattern>(
            label: 'Pattern',
            value: _drawPattern,
            values: PianoRollDrawPattern.values,
            text: (value) => value == PianoRollDrawPattern.single
                ? 'Single / drag length'
                : 'Repeat on grid',
            onChanged: (value) {
              setState(() => _drawPattern = value);
              widget.onDrawPatternChanged?.call(value);
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Long-press Draw to return here.',
            style: TextStyle(color: PianoRollTheme.labelMuted, fontSize: 11),
          ),
        ],
      );

  double get _noteLengthValue {
    const values = [0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0];
    return values.reduce((a, b) => (a - _settings.defaultNoteBeats).abs() <
            (b - _settings.defaultNoteBeats).abs()
        ? a
        : b);
  }

  static String _noteLengthLabel(double value) => switch (value) {
        0.125 => '1/32',
        0.25 => '1/16',
        0.5 => '1/8',
        1.0 => '1/4',
        2.0 => '1/2',
        4.0 => '1 bar',
        _ => '2 bars',
      };
}
