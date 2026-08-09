part of 'midi_comp_context_bar.dart';

class MidiCompLockedBar extends StatelessWidget {
  const MidiCompLockedBar({
    super.key,
    this.onReopen,
  });

  final VoidCallback? onReopen;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EDIT mode — comp markers locked',
                      style: TextStyle(
                        color: PianoRollTheme.saveOk,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Re-open to edit takes and markers.',
                      style: TextStyle(
                        color: PianoRollTheme.labelMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (onReopen != null)
                TextButton(
                  onPressed: onReopen,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF2A2A36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF3A3A48)),
                    ),
                  ),
                  child: const Text(
                    'Re-open',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
