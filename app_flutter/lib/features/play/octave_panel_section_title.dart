part of 'octave_panel.dart';

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          color: PlayDeckTheme.railLabel,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
