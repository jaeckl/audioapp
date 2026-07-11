part of 'perform_panel.dart';

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.rootMidi,
    required this.activeOffset,
    required this.onDown,
    required this.onUp,
    required this.labelFor,
  });

  final int rootMidi;
  final int activeOffset;
  final void Function(int rootOffset) onDown;
  final VoidCallback onUp;
  final String Function(int root) labelFor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var offset = -1; offset <= 1; offset++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => onDown(offset * 12),
                onPointerUp: (_) => onUp(),
                onPointerCancel: (_) => onUp(),
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: offset == activeOffset
                          ? PlayDeckTheme.padActive
                          : PlayDeckTheme.padIdle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      labelFor(rootMidi + offset * 12),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PlayDeckTheme.optionLabel,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
