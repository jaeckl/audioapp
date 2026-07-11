part of 'mpc_pad_grid.dart';

class _PadDrag {
  _PadDrag({required this.index, required this.origin, required this.last});
  final int index;
  final Offset origin;
  Offset last;
}
