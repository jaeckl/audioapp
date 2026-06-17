import 'package:flutter/material.dart';

import 'play_deck_theme.dart';
import 'play_scale.dart';

/// 12-step toggle grid + a "Save" field. Returns a new custom scale on save.
class ScaleBuilderPanel extends StatefulWidget {
  const ScaleBuilderPanel({
    super.key,
    required this.onSave,
  });

  final void Function(PlayScale scale) onSave;

  @override
  State<ScaleBuilderPanel> createState() => _ScaleBuilderPanelState();
}

class _ScaleBuilderPanelState extends State<ScaleBuilderPanel> {
  late Set<int> _picked = {...PlayScale.major.intervals};
  final _nameCtrl = TextEditingController(text: 'Custom');
  int _rootOffset = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggle(int semitone) {
    setState(() {
      if (semitone == 0) {
        _picked.add(0);
      } else if (_picked.contains(semitone)) {
        _picked.remove(semitone);
      } else {
        _picked.add(semitone);
      }
    });
  }

  void _reset() {
    setState(() {
      _picked = {...PlayScale.major.intervals};
      _rootOffset = 0;
    });
  }

  void _save() {
    final intervals = _picked.toList()..sort();
    final name = _nameCtrl.text.trim().isEmpty ? 'Custom' : _nameCtrl.text.trim();
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    widget.onSave(PlayScale(id: id, label: name, intervals: intervals));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PlayDeckTheme.panelBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          const _SectionTitle(text: 'Custom scale'),
          const Text(
            'Tap the 12 notes you want in your scale. The root note is included by default.',
            style: TextStyle(fontSize: 11, color: PlayDeckTheme.railLabel),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var s = 0; s < 12; s++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: s == 11 ? 0 : 2),
                    child: _SemitoneButton(
                      label: PlayScale.noteNames[s],
                      selected: _picked.contains(s),
                      isRoot: s == _rootOffset,
                      onTap: () => _toggle(s),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Root',
                  style: TextStyle(fontSize: 11, color: PlayDeckTheme.railLabel)),
              const SizedBox(width: 8),
              for (var s = 0; s < 12; s++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: s == 11 ? 0 : 2),
                    child: _SemitoneButton(
                      label: PlayScale.noteNames[s],
                      selected: s == _rootOffset,
                      small: true,
                      onTap: () => setState(() => _rootOffset = s),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: PlayDeckTheme.optionLabel, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    isDense: true,
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: PlayDeckTheme.railLabel),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Pill(label: 'Reset', selected: false, onTap: _reset),
              const SizedBox(width: 6),
              _Pill(label: 'Save', selected: true, onTap: _save),
            ],
          ),
        ],
      ),
    );
  }
}

class _SemitoneButton extends StatelessWidget {
  const _SemitoneButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isRoot = false,
    this.small = false,
  });

  final String label;
  final bool selected;
  final bool isRoot;
  final bool small;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isRoot
          ? PlayDeckTheme.optionActive
          : selected
              ? const Color(0xFF3A3A44)
              : PlayDeckTheme.optionIdle,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: small ? 1.0 : 1.6,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: small ? 9 : 11,
                color: isRoot
                    ? Colors.black
                    : selected
                        ? PlayDeckTheme.optionLabel
                        : PlayDeckTheme.railLabel,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PlayDeckTheme.optionActive : PlayDeckTheme.optionIdle,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.black : PlayDeckTheme.optionLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          color: PlayDeckTheme.railLabel,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
