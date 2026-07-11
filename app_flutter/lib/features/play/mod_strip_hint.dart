part of 'mod_strip.dart';

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        color: PlayDeckTheme.railLabel,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
