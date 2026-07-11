part of 'modulation_grid.dart';

class _ModulatorTile extends StatefulWidget {
  const _ModulatorTile({
    required this.lfo,
    required this.size,
    required this.playheadBeat,
    required this.bpm,
    required this.elapsedSeconds,
    required this.isSelected,
    required this.isConnectMode,
    required this.targetsPanelVisible,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
    this.onShowTargets,
    this.onHideTargets,
  });

  final LfoSnapshot lfo;
  final double size;
  final double playheadBeat;
  final int bpm;
  final double elapsedSeconds;
  final bool isSelected;
  final bool isConnectMode;
  final bool targetsPanelVisible;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;
  final VoidCallback? onShowTargets;
  final VoidCallback? onHideTargets;

  @override
  State<_ModulatorTile> createState() => _ModulatorTileState();
}
