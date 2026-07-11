part of 'transport_bar.dart';

class _MetronomeMenu extends StatefulWidget {
  const _MetronomeMenu(
      {required this.enabled,
      required this.level,
      required this.countInBars,
      required this.onChanged});
  final bool enabled;
  final double level;
  final int countInBars;
  final void Function(bool enabled, double level, int countInBars) onChanged;
  @override
  State<_MetronomeMenu> createState() => _MetronomeMenuState();
}
