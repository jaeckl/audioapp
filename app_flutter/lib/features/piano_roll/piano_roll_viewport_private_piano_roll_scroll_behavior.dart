part of 'piano_roll_viewport.dart';

class _PianoRollScrollBehavior extends MaterialScrollBehavior {
  const _PianoRollScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
