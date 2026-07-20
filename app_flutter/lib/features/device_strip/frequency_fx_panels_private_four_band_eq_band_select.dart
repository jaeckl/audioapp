part of 'frequency_fx_panels.dart';

/// LS · LM · HM · HS — Filter-style underline band select in the EQ plate.
class _FourBandEqBandSelect extends StatelessWidget {
  const _FourBandEqBandSelect({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const labels = ['LS', 'LM', 'HM', 'HS'];

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DevicePanelTheme.modeRowHeight,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                key: ValueKey('eq-band-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(i),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: i == selectedIndex
                          ? FourBandEqDevicePanel.bandColors[i]
                              .withValues(alpha: 0.14)
                          : Colors.transparent,
                    ),
                    Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: i == selectedIndex
                              ? FourBandEqDevicePanel.bandColors[i]
                              : Colors.white.withValues(alpha: 0.46),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (i == selectedIndex)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ColoredBox(
                          color: FourBandEqDevicePanel.bandColors[i],
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
  }
}
