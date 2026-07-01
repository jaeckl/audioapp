import 'package:flutter/material.dart';

import '../play/play_deck_layout.dart';
import '../play/play_scale.dart';
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
  });

  final PianoRollGridSettings initialSettings;
  final PianoRollScaleSettings initialScaleSettings;
  final bool showScaleControls;
  final ValueChanged<PianoRollGridSettings> onChanged;
  final ValueChanged<PianoRollScaleSettings> onScaleChanged;

  /// Opens the grid panel above [bottomInset] px of chrome (e.g. piano-roll PlayDeck).
  static Future<void> show(
    BuildContext context, {
    required PianoRollGridSettings settings,
    required ValueChanged<PianoRollGridSettings> onChanged,
    PianoRollScaleSettings scaleSettings = const PianoRollScaleSettings(),
    ValueChanged<PianoRollScaleSettings>? onScaleChanged,
    bool showScaleControls = false,
    double bottomInset = 0,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: PianoRollTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: PianoRollGridSheet(
          initialSettings: settings,
          initialScaleSettings: scaleSettings,
          showScaleControls: showScaleControls,
          onChanged: onChanged,
          onScaleChanged: onScaleChanged ?? (_) {},
        ),
      ),
    );
  }

  @override
  State<PianoRollGridSheet> createState() => _PianoRollGridSheetState();
}

class _PianoRollGridSheetState extends State<PianoRollGridSheet> {
  late PianoRollGridSettings _settings;
  late PianoRollScaleSettings _scaleSettings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _scaleSettings = widget.initialScaleSettings;
  }

  void _update(PianoRollGridSettings next) {
    setState(() => _settings = next);
    widget.onChanged(next);
  }

  void _updateScale(PianoRollScaleSettings next) {
    setState(() => _scaleSettings = next);
    widget.onScaleChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomSafe),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Grid',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Snap'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final snap in PianoRollSnap.values)
                  _Pill(
                    label: snap.shortLabel,
                    active: _settings.snap == snap,
                    onTap: () => _update(_settings.copyWith(snap: snap)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Triplet'),
            const SizedBox(height: 8),
            Row(
              children: [
                _Pill(
                  label: 'Off',
                  active: !_settings.triplet,
                  onTap: () => _update(_settings.copyWith(triplet: false)),
                ),
                const SizedBox(width: 6),
                _Pill(
                  label: 'On',
                  active: _settings.triplet,
                  onTap: () => _update(_settings.copyWith(triplet: true)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Default note length'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Pill(
                  label: '1/4',
                  active: _settings.defaultNoteBeats == 0.25,
                  onTap: () =>
                      _update(_settings.copyWith(defaultNoteBeats: 0.25)),
                ),
                _Pill(
                  label: '1/2',
                  active: _settings.defaultNoteBeats == 0.5,
                  onTap: () =>
                      _update(_settings.copyWith(defaultNoteBeats: 0.5)),
                ),
                _Pill(
                  label: '1 bar',
                  active: _settings.defaultNoteBeats == 4.0,
                  onTap: () =>
                      _update(_settings.copyWith(defaultNoteBeats: 4.0)),
                ),
                _Pill(
                  label: '2 bars',
                  active: _settings.defaultNoteBeats == 8.0,
                  onTap: () =>
                      _update(_settings.copyWith(defaultNoteBeats: 8.0)),
                ),
              ],
            ),
            if (widget.showScaleControls) ...[
              const SizedBox(height: 16),
              const _SectionTitle('Scale'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < PlayScale.noteNames.length; i++)
                    _Pill(
                      label: PlayScale.noteNames[i],
                      active: _scaleSettings.rootPitchClass == i,
                      onTap: () => _updateScale(
                        _scaleSettings.copyWith(rootPitchClass: i),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final scale in PlayScale.presets)
                    _Pill(
                      label: scale.label,
                      active: _scaleSettings.scale.id == scale.id,
                      onTap: () => _updateScale(
                        _scaleSettings.copyWith(scale: scale),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Pill(
                    label: 'Highlight',
                    active: _scaleSettings.highlight,
                    onTap: () => _updateScale(
                      _scaleSettings.copyWith(
                        highlight: !_scaleSettings.highlight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _Pill(
                    label: 'Snap pitch',
                    active: _scaleSettings.snapToScale,
                    onTap: () => _updateScale(
                      _scaleSettings.copyWith(
                        snapToScale: !_scaleSettings.snapToScale,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionTitle('Chord painter'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final quality in ChordQuality.values)
                    _Pill(
                      label: quality == ChordQuality.off
                          ? 'Single'
                          : quality.label,
                      active: _scaleSettings.chordQuality == quality,
                      onTap: () => _updateScale(
                        _scaleSettings.copyWith(chordQuality: quality),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: PianoRollTheme.label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF3A3A50) : const Color(0xFF22222C),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
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
}
