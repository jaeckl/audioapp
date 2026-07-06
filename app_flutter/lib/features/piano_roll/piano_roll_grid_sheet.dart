import 'package:flutter/material.dart';

import '../play/play_scale.dart';
import '../play/play_deck_layout.dart';
import 'editor_view_range.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_scale.dart';
import 'piano_roll_theme.dart';

class PianoRollGridSheet extends StatefulWidget {
  const PianoRollGridSheet({
    super.key,
    required this.initialSettings,
    required this.initialScaleSettings,
    required this.showScaleControls,
    required this.onChanged,
    required this.onScaleChanged,
    this.showViewRange = false,
    this.initialViewRangeBars = EditorViewRange.defaultBars,
    this.onViewRangeChanged,
    this.drawControls = false,
    this.initialDrawPattern = PianoRollDrawPattern.single,
    this.onDrawPatternChanged,
  });

  final PianoRollGridSettings initialSettings;
  final PianoRollScaleSettings initialScaleSettings;
  final bool showScaleControls;
  final bool showViewRange;
  final int initialViewRangeBars;
  final ValueChanged<int>? onViewRangeChanged;
  final bool drawControls;
  final PianoRollDrawPattern initialDrawPattern;
  final ValueChanged<PianoRollDrawPattern>? onDrawPatternChanged;
  final ValueChanged<PianoRollGridSettings> onChanged;
  final ValueChanged<PianoRollScaleSettings> onScaleChanged;

  static Future<void> show(
    BuildContext context, {
    required PianoRollGridSettings settings,
    required ValueChanged<PianoRollGridSettings> onChanged,
    PianoRollScaleSettings scaleSettings = const PianoRollScaleSettings(),
    ValueChanged<PianoRollScaleSettings>? onScaleChanged,
    bool showScaleControls = false,
    double bottomInset = 0,
  }) =>
      showView(
        context,
        settings: settings,
        onChanged: onChanged,
        scaleSettings: scaleSettings,
        onScaleChanged: onScaleChanged,
        showScaleControls: showScaleControls,
        viewRangeBars: EditorViewRange.defaultBars,
        onViewRangeChanged: null,
      );

  /// Unified view sheet: zoom range, grid snap, and scale controls.
  static Future<void> showView(
    BuildContext context, {
    required PianoRollGridSettings settings,
    required ValueChanged<PianoRollGridSettings> onChanged,
    PianoRollScaleSettings scaleSettings = const PianoRollScaleSettings(),
    ValueChanged<PianoRollScaleSettings>? onScaleChanged,
    bool showScaleControls = false,
    required int viewRangeBars,
    ValueChanged<int>? onViewRangeChanged,
  }) =>
      _showPopup(
        context,
        alignBottom: false,
        panelHeight: showScaleControls ? 460 : 380,
        child: PianoRollGridSheet(
          initialSettings: settings,
          initialScaleSettings: scaleSettings,
          showScaleControls: showScaleControls,
          showViewRange: onViewRangeChanged != null,
          initialViewRangeBars: viewRangeBars,
          onViewRangeChanged: onViewRangeChanged,
          onChanged: onChanged,
          onScaleChanged: onScaleChanged ?? (_) {},
        ),
      );

  static Future<void> showDraw(
    BuildContext context, {
    required PianoRollGridSettings settings,
    required ValueChanged<PianoRollGridSettings> onChanged,
    required PianoRollScaleSettings scaleSettings,
    required ValueChanged<PianoRollScaleSettings> onScaleChanged,
    required bool showScaleControls,
    PianoRollDrawPattern drawPattern = PianoRollDrawPattern.single,
    ValueChanged<PianoRollDrawPattern>? onDrawPatternChanged,
    double bottomInset = 0,
  }) =>
      _showPopup(
        context,
        alignBottom: true,
        child: PianoRollGridSheet(
          initialSettings: settings,
          initialScaleSettings: scaleSettings,
          showScaleControls: showScaleControls,
          drawControls: true,
          initialDrawPattern: drawPattern,
          onDrawPatternChanged: onDrawPatternChanged,
          onChanged: onChanged,
          onScaleChanged: onScaleChanged,
        ),
      );

  static Future<void> _showPopup(
    BuildContext context, {
    required bool alignBottom,
    required Widget child,
    double panelHeight = 390,
  }) {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final size = overlay.size;
    final position = alignBottom
        ? RelativeRect.fromLTRB(8, size.height - panelHeight, size.width - 292, 56)
        : RelativeRect.fromLTRB(size.width - 292, 52, 8, size.height - 52);
    return showMenu<void>(
      context: context,
      position: position,
      color: const Color(0xFF1A1A22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF343442)),
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: SizedBox(width: 260, child: child),
        ),
      ],
    );
  }

  @override
  State<PianoRollGridSheet> createState() => _PianoRollGridSheetState();
}

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

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: PianoRollTheme.labelMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: active ? const Color(0xFF3A3A50) : const Color(0xFF22222C),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? Colors.white : PianoRollTheme.labelMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.values,
    required this.text,
    this.onChanged,
  });
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) text;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(label),
          const SizedBox(height: 5),
          DropdownButtonFormField<T>(
            initialValue: value,
            isDense: true,
            isExpanded: true,
            dropdownColor: const Color(0xFF22222C),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF22222C),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: [
              for (final item in values)
                DropdownMenuItem(value: item, child: Text(text(item))),
            ],
            onChanged: onChanged == null
                ? null
                : (item) {
                    if (item != null) onChanged!(item);
                  },
          ),
        ],
      );
}
