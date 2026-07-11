part of 'transport_bar.dart';

class _JumpToStartButton extends StatelessWidget {
  const _JumpToStartButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Jump to start',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 32,
            height: double.infinity,
            child: Icon(
              Icons.skip_previous_rounded,
              color: onPressed == null
                  ? TransportBarTheme.textMuted
                  : TransportBarTheme.textSecondary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
