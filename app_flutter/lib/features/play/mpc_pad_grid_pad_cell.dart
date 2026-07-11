part of 'mpc_pad_grid.dart';

class _PadCell extends StatefulWidget {
  const _PadCell({
    required this.active,
    required this.onDown,
    required this.onUp,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerEnd,
  });

  final bool active;
  final void Function(double localY, double height) onDown;
  final VoidCallback onUp;
  final void Function(int pointer, Offset local) onPointerDown;
  final void Function(int pointer, Offset local, Size padSize) onPointerMove;
  final Future<void> Function(int pointer) onPointerEnd;

  @override
  State<_PadCell> createState() => _PadCellState();
}
