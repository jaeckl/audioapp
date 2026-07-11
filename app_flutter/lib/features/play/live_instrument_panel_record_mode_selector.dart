part of 'live_instrument_panel.dart';

class _RecordModeSelector extends StatelessWidget {
  const _RecordModeSelector({
    required this.mode,
    required this.onChanged,
  });

  final RecordWriteMode mode;
  final ValueChanged<RecordWriteMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RecordWriteMode>(
      tooltip: 'Record mode',
      initialValue: mode,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final value in RecordWriteMode.values)
          PopupMenuItem(value: value, child: Text(value.label)),
      ],
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF5A2A30))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fiber_smart_record,
                size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              mode.label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
