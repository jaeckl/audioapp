part of 'device_strip_slot.dart';

extension DeviceStripSlotStateSeqsyncdivisionsOperation
    on _DeviceStripSlotState {
  Widget _seqSyncDivisions(
      LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    return Row(
      children: List.generate(5, (i) {
        final active = (mod.syncDivision.clamp(1, 5) - 1) == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => onUpdate('syncDivision', (i + 1).toDouble()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? _seqAccent.withValues(alpha: 0.2)
                    : const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: active ? _seqAccent : Colors.white24,
                  width: active ? 1.0 : 0.5,
                ),
              ),
              child: Text(
                _seqSyncLabels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? _seqAccent : Colors.white54,
                  fontSize: 8,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
