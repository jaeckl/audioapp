part of 'piano_roll_edit_sheet.dart';

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: PianoRollTheme.label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
