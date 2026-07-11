part of 'device_strip_slot.dart';

extension DeviceStripSlotStateSeqheaderOperation on _DeviceStripSlotState {
  Widget _seqHeader(
      LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    final stepOptions = [4, 8, 12, 16, 24, 32];
    final currentSteps =
        stepOptions.contains(mod.sequencerSteps) ? mod.sequencerSteps : 16;
    return Row(
      children: [
        Text(
          'SEQ ${mod.id}',
          style: const TextStyle(
              color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        SizedBox(
          width: 44,
          child:
              DeviceStripSlotStateSeqpolaritytoggleOperation._seqPolarityToggle(
                  mod, onUpdate),
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: currentSteps,
          dropdownColor: const Color(0xFF1A1A24),
          isDense: true,
          style: const TextStyle(
              color: _seqAccent, fontSize: 10, fontWeight: FontWeight.w700),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: _seqAccent, size: 14),
          items: stepOptions
              .map((n) => DropdownMenuItem<int>(
                    value: n,
                    child: Text('$n',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onUpdate('steps', v.toDouble());
          },
        ),
      ],
    );
  }
}
