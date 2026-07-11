part of 'sample_editor_snap_sheet.dart';

class _SampleEditSnapSheetBodyState extends State<_SampleEditSnapSheetBody> {
  late SampleEditSnapSettings _settings = widget.initialSettings;

  void _set(SampleEditSnapSettings value) {
    setState(() => _settings = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Edit snap',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Snaps trim handles and slice markers to source divisions.',
            style: TextStyle(
                color: AutomationEditorTheme.labelMuted.withValues(alpha: .9),
                fontSize: 11,
                height: 1.3),
          ),
          const SizedBox(height: 12),
          const Text('SNAP',
              style: TextStyle(
                  color: AutomationEditorTheme.labelMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _SnapPill(
                label: 'Off',
                active: _settings.snap == SampleEditSnap.off,
                onTap: () => _set(_settings.copyWith(snap: SampleEditSnap.off)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SnapPill(
                label: 'On',
                active: _settings.snap != SampleEditSnap.off,
                onTap: () =>
                    _set(_settings.copyWith(snap: SampleEditSnap.sixteenth)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('DIVISION',
              style: TextStyle(
                  color: AutomationEditorTheme.labelMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: SampleEditSnap.values
                .where((value) => value != SampleEditSnap.off)
                .map(
                  (value) => _SnapPill(
                    label: value.shortLabel,
                    active: _settings.snap == value,
                    compact: true,
                    onTap: () => _set(_settings.copyWith(snap: value)),
                  ),
                )
                .toList(),
          ),
        ],
      );
}
