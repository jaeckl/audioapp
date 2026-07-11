part of 'automation_editor_viewport.dart';

class _AutomationScrollBehavior extends MaterialScrollBehavior {
  const _AutomationScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
