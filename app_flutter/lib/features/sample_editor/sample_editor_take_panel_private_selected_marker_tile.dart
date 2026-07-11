part of 'sample_editor_take_panel.dart';

class _SelectedMarkerTile extends StatelessWidget {
  const _SelectedMarkerTile({required this.beat});

  final double? beat;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 130,
        height: 66,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .07)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SELECTED MARKER',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5)),
                Text(beat == null ? 'None' : '${beat!.toStringAsFixed(2)}b',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: beat == null ? Colors.white38 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
              ]),
        ),
      );
}
