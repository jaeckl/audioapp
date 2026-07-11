part of 'play_keyboard.dart';

class _KeyDrag {
  _KeyDrag({required this.pitch, required this.origin, required this.last});
  final int pitch;
  final Offset origin;
  Offset last;
}
