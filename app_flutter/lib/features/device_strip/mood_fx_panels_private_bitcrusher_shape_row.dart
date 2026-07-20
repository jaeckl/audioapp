part of 'mood_fx_panels.dart';

/// Crush shape icons — Filter-style underline group in the plate.
class _BitcrusherShapeRow extends StatelessWidget {
  const _BitcrusherShapeRow({
    required this.selectedIndex,
    required this.onSelected,
    required this.modulated,
    required this.automated,
    required this.modulationAmount,
    required this.connectModeActive,
    required this.linkModeActive,
    this.onModulationAssign,
    this.onLinkTap,
    this.onAutomateRequest,
  });

  static const icons = [
    Icons.horizontal_rule_rounded,
    Icons.waves_rounded,
    Icons.change_history_rounded,
    Icons.stacked_line_chart_rounded,
  ];

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool modulated;
  final bool automated;
  final double modulationAmount;
  final bool connectModeActive;
  final bool linkModeActive;
  final ValueChanged<double>? onModulationAssign;
  final VoidCallback? onLinkTap;
  final VoidCallback? onAutomateRequest;

  @override
  Widget build(BuildContext context) {
    return EffectiveParameterValueBuilder(
      parameterId: 'bcShape',
      fallbackValue: selectedIndex / 3,
      active: automated,
      builder: (context, live) {
        final selected = (live * 3).round().clamp(0, 3);
        return LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth.isFinite && constraints.maxWidth > 0
                    ? constraints.maxWidth
                    : 200.0;
            return HorizontalGroupShell(
              width: width,
              height: DevicePanelTheme.modeRowHeight,
              value: selected.toDouble(),
              maxValue: 3,
              accent: BitcrusherFxPanel.accent,
              flat: true,
              modulationActive: modulated,
              modulationAmount: modulationAmount,
              automationActive: automated,
              connectModeActive: connectModeActive,
              linkModeActive: linkModeActive,
              onModulationAssign: onModulationAssign,
              onLinkTap: onLinkTap,
              onAutomateRequest: onAutomateRequest,
              child: Row(
                children: [
                  for (var i = 0; i < icons.length; i++)
                    Expanded(
                      child: GestureDetector(
                        key: ValueKey('bitcrusher-shape-$i'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelected(i),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(
                              color: i == selected
                                  ? BitcrusherFxPanel.accent
                                      .withValues(alpha: 0.12)
                                  : Colors.transparent,
                            ),
                            Center(
                              child: Icon(
                                icons[i],
                                size: 14,
                                color: i == selected
                                    ? BitcrusherFxPanel.accent
                                    : Colors.white.withValues(alpha: 0.46),
                              ),
                            ),
                            if (i == selected)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ColoredBox(
                                  color: BitcrusherFxPanel.accent,
                                  child: const SizedBox(height: 2),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
