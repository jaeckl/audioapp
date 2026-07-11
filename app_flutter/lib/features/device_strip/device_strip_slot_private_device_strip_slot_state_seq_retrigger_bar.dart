part of 'device_strip_slot.dart';

extension DeviceStripSlotStateSeqretriggerbarOperation
    on _DeviceStripSlotState {
  Widget _seqRetriggerBar(
      LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    const labels = ['Free', 'Sync', 'On note'];
    const values = [0, 1, 2];
    final selected = mod.retrigger.clamp(0, 2);
    return SizedBox(
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(3, (i) {
              final active = selected == values[i];
              return Expanded(
                child: Material(
                  color: active
                      ? _seqAccent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => onUpdate('retrigger', values[i].toDouble()),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: active ? _seqAccent : Colors.white38,
                          fontSize: 9,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
