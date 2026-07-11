part of 'modulation_grid.dart';

class _GridSlot {
  const _GridSlot.modulator(this.lfo) : isAdd = false;
  const _GridSlot.add()
      : lfo = null,
        isAdd = true;

  final LfoSnapshot? lfo;
  final bool isAdd;
}
