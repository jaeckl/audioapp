part of 'arrangement_view.dart';

class _MidiClipBlock extends StatelessWidget {
  const _MidiClipBlock({
    required this.clip,
    required this.trackAccent,
    required this.highlighted,
    required this.selected,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    this.onDoubleTap,
  });

  final MidiClipSnapshot clip;
  final Color trackAccent;
  final bool highlighted;
  final bool selected;
  final VoidCallback onTap;
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
                renderer: MidiClipRenderer(clip, trackAccent: trackAccent),
                highlighted: highlighted || selected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
