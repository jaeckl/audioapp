part of 'transport_bar.dart';

class _MetronomeMenuState extends State<_MetronomeMenu> {
  late bool enabled = widget.enabled;
  late double level = widget.level;
  late int countInBars = widget.countInBars;
  void commit() => widget.onChanged(enabled, level, countInBars);
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 250,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Metronome',
                      style: TextStyle(
                          color: TransportBarTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600))),
              Switch(
                  value: enabled,
                  onChanged: (v) {
                    setState(() => enabled = v);
                    commit();
                  })
            ]),
            const SizedBox(height: 8),
            const _SnapGridSectionTitle('Click level'),
            Slider(
                value: level,
                min: 0,
                max: 1,
                onChanged: (v) {
                  setState(() => level = v);
                  commit();
                }),
            const _SnapGridSectionTitle('Count-in'),
            const SizedBox(height: 8),
            Row(children: [
              for (final bars in const [0, 1, 2, 4])
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Material(
                            color: countInBars == bars
                                ? TransportBarTheme.menuPillActiveFill
                                : TransportBarTheme.menuPillIdle,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                                onTap: () {
                                  setState(() => countInBars = bars);
                                  commit();
                                },
                                child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(bars == 0 ? 'Off' : '$bars',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: countInBars == bars
                                                ? TransportBarTheme
                                                    .menuPillActiveText
                                                : TransportBarTheme
                                                    .textSecondary)))))))
            ])
          ]));
}
