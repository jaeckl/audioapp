part of 'midi_comp_context_bar.dart';

class MidiCompLockedBar extends StatelessWidget {
  const MidiCompLockedBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
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
                'Re-open comp from ⋯ menu to edit takes and markers.',
                style: TextStyle(
                  color: PianoRollTheme.labelMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
