part of 'modulation_grid.dart';

class _GridColumn extends StatelessWidget {
  const _GridColumn({
    required this.slots,
    required this.cellSize,
    required this.isNarrow,
    required this.selectedLfoId,
    required this.connectModeLfoId,
    required this.playheadBeat,
    required this.bpm,
    required this.elapsedSeconds,
    required this.targetsPanelVisible,
    required this.onLfoTap,
    required this.onLfoLongPress,
    required this.onRemoveLfo,
    required this.onShowTargets,
    required this.onHideTargets,
    required this.onShowAddMenu,
  });

  final List<_GridSlot> slots;
  final double cellSize;
  final bool isNarrow;
  final int? selectedLfoId;
  final int? connectModeLfoId;
  final double playheadBeat;
  final int bpm;
  final double elapsedSeconds;
  final bool targetsPanelVisible;
  final ValueChanged<int> onLfoTap;
  final ValueChanged<int> onLfoLongPress;
  final ValueChanged<int> onRemoveLfo;
  final ValueChanged<int>? onShowTargets;
  final ValueChanged<int>? onHideTargets;
  final VoidCallback onShowAddMenu;

  @override
  Widget build(BuildContext context) {
    final tileW = isNarrow ? cellSize / 3 : cellSize;
    final tileH = cellSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) const SizedBox(height: ModulationGrid.cellGap),
          _buildTile(slots[i], tileW, tileH),
        ],
      ],
    );
  }

  Widget _buildTile(_GridSlot slot, double tileW, double tileH) {
    if (slot.isAdd) {
      return _AddModulatorTile(
        onPressed: onShowAddMenu,
        width: tileW,
        height: tileH,
      );
    }
    final lfo = slot.lfo!;
    return _ModulatorTile(
      lfo: lfo,
      size: tileW,
      playheadBeat: playheadBeat,
      bpm: bpm,
      elapsedSeconds: elapsedSeconds,
      isSelected: lfo.id == selectedLfoId,
      isConnectMode: lfo.id == connectModeLfoId,
      targetsPanelVisible: targetsPanelVisible,
      onTap: () => onLfoTap(lfo.id),
      onLongPress: () => onLfoLongPress(lfo.id),
      onRemove: () => onRemoveLfo(lfo.id),
      onShowTargets:
          onShowTargets != null ? () => onShowTargets!(lfo.id) : null,
      onHideTargets:
          onHideTargets != null ? () => onHideTargets!(lfo.id) : null,
    );
  }
}
