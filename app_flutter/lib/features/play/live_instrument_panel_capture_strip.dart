part of 'live_instrument_panel.dart';

class _CaptureStrip extends StatelessWidget {
  const _CaptureStrip({
    required this.armed,
    required this.recordWriteMode,
    required this.quantize,
    required this.latch,
    required this.metronome,
    required this.onArmToggle,
    required this.onRecordWriteModeChanged,
    required this.onLatchToggle,
    required this.onMetronomeToggle,
  });

  final bool armed;
  final RecordWriteMode recordWriteMode;
  final CaptureQuantize quantize;
  final bool latch;
  final bool metronome;
  final VoidCallback onArmToggle;
  final ValueChanged<RecordWriteMode> onRecordWriteModeChanged;
  final VoidCallback onLatchToggle;
  final VoidCallback onMetronomeToggle;

  @override
  Widget build(BuildContext context) {
    if (!armed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            _SimpleTextButton(
              icon: Icons.fiber_manual_record,
              color: Colors.redAccent,
              label: 'ARM',
              onTap: onArmToggle,
            ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFF2A1A1E),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            _SimpleTextButton(
              icon: Icons.fiber_manual_record,
              color: Colors.redAccent,
              label: 'ARMED',
              onTap: onArmToggle,
            ),
            const VerticalDivider(width: 1, color: Color(0xFF5A2A30)),
            _SimpleTextButton(
              icon: latch ? Icons.lock : Icons.lock_open,
              color: latch ? Colors.amber : Colors.white54,
              label: 'Latch',
              onTap: onLatchToggle,
            ),
            _SimpleTextButton(
              icon: metronome ? Icons.timer : Icons.timer_outlined,
              color: metronome ? Colors.amber : Colors.white54,
              label: quantize.label,
              onTap: onMetronomeToggle,
            ),
            Expanded(
              child: _RecordModeSelector(
                mode: recordWriteMode,
                onChanged: onRecordWriteModeChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
