part of 'device_strip_slot.dart';

extension DeviceStripSlotStateSeqpolaritytoggleOperation
    on _DeviceStripSlotState {
  static Widget _seqPolarityToggle(
      LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    final selected = mod.polarity.clamp(0, 1);
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
            children: List.generate(2, (i) {
              final active = selected == i;
              return Expanded(
                child: Material(
                  color: active
                      ? _seqAccent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => onUpdate('polarity', i.toDouble()),
                    child: Center(
                      child: Text(
                        ['\u00B1', '+'][i],
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
