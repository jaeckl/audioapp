part of 'arrangement_view.dart';

class _AutomationClipBlock extends StatelessWidget {
  const _AutomationClipBlock({
    required this.clip,
    required this.highlighted,
    required this.selected,
    required this.linkActive,
    this.onLinkToggle,
    this.onTap,
    this.onDoubleTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final AutomationClipSnapshot clip;
  final bool highlighted;
  final bool selected;
  final bool linkActive;
  final VoidCallback? onLinkToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final GestureLongPressStartCallback onDragStart;
  final GestureLongPressMoveUpdateCallback onDragUpdate;
  final GestureLongPressEndCallback onDragEnd;
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: highlighted ? null : onTap,
            onDoubleTap: onDoubleTap,
            onLongPressStart: onDragStart,
            onLongPressMoveUpdate: onDragUpdate,
            onLongPressEnd: onDragEnd,
            onLongPressCancel: onDragCancel,
            child: Opacity(
              opacity: highlighted ? 0.35 : 1,
              child: ArrangementClipChrome(
                renderer: AutomationClipRenderer(clip),
                highlighted: highlighted || selected || linkActive,
              ),
            ),
          ),
          if (onLinkToggle != null)
            Positioned(
              top: -10,
              left: 6,
              child: AutomationClipLinkChip(
                active: linkActive,
                onTap: onLinkToggle!,
              ),
            ),
        ],
      ),
    );
  }
}
