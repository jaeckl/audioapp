part of 'scale_builder_panel.dart';

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
    final name =
        _nameCtrl.text.trim().isEmpty ? 'Custom' : _nameCtrl.text.trim();
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
                  style:
                      TextStyle(fontSize: 11, color: PlayDeckTheme.railLabel)),
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
                  style: const TextStyle(
                      color: PlayDeckTheme.optionLabel, fontSize: 13),
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
