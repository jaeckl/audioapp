part of 'mod_strip.dart';

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 9, color: PlayDeckTheme.railLabel),
    );
  }
}
