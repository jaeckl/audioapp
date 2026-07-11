part of 'transport_bar.dart';

class _InlineMetronomeButton extends StatelessWidget {
  const _InlineMetronomeButton({
    required this.enabled,
    required this.level,
    required this.countInBars,
    this.onChanged,
  });

  final bool enabled;
  final double level;
  final int countInBars;
  final void Function(bool, double, int)? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: double.infinity,
      child: PopupMenuButton<void>(
        tooltip: enabled ? 'Metronome on' : 'Metronome off',
        enabled: onChanged != null,
        padding: EdgeInsets.zero,
        color: TransportBarTheme.menuBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: TransportBarTheme.chipBorder),
        ),
        icon: Icon(
          enabled ? Icons.timer : Icons.timer_outlined,
          size: 19,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : TransportBarTheme.textSecondary,
        ),
        itemBuilder: (_) => [
          PopupMenuItem<void>(
            enabled: false,
            padding: const EdgeInsets.all(14),
            child: _MetronomeMenu(
              enabled: enabled,
              level: level,
              countInBars: countInBars,
              onChanged: onChanged ?? (_, __, ___) {},
            ),
          ),
        ],
      ),
    );
  }
}
