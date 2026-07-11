part of 'arrangement_view.dart';

class _FreezeClipBlock extends StatelessWidget {
  const _FreezeClipBlock({required this.freeze});

  final TrackFreezeSnapshot freeze;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ArrangementClipChrome(
        renderer: FreezeClipRenderer(freeze),
        highlighted: false,
      ),
    );
  }
}
