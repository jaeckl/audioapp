part of 'sample_editor_take_panel.dart';

class _TakeSplitButton extends StatelessWidget {
  const _TakeSplitButton({required this.beatLabel, required this.onTap});

  final String beatLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        height: 86,
        child: Material(
          color: ArrangementLoopRegionTheme.color.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: ArrangementLoopRegionTheme.color
                        .withValues(alpha: .45)),
              ),
              child: Row(children: [
                const Icon(Icons.call_split, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Split At Playhead',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Create boundary at $beatLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      );
}
