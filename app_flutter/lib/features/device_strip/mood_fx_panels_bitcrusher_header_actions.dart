part of 'mood_fx_panels.dart';

class BitcrusherHeaderActions extends StatelessWidget {
  const BitcrusherHeaderActions({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final BitcrusherDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    const labels = ['Classic', 'Impact', 'Sub', 'Organic'];
    final antiAlias = device.bcFilter > .82
        ? 0
        : device.bcFilter > .55
            ? 1
            : 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
      child: Row(children: [
        EffectiveParameterValueBuilder(
          parameterId: 'bcMode',
          fallbackValue: device.bcMode / 3,
          active: automatedParams.contains('bcMode'),
          builder: (context, liveValue) {
            final selected = (liveValue * 3).round().clamp(0, 3);
            return _HorizontalGroupShell(
              width: 210,
              height: 32,
              value: selected.toDouble(),
              maxValue: 3,
              accent: BitcrusherFxPanel.accent,
              modulationActive: modulatedParams.contains('bcMode'),
              modulationAmount: modulationAmounts['bcMode'] ?? 0,
              automationActive: automatedParams.contains('bcMode'),
              connectModeActive: connectModeLfoId != null,
              linkModeActive: automationLinkActive,
              onModulationAssign: onModulationAssign == null
                  ? null
                  : (amount) => onModulationAssign!('bcMode', amount),
              onLinkTap: onAutomationLinkTap == null
                  ? null
                  : () => onAutomationLinkTap!('bcMode'),
              onAutomateRequest: onAutomateParameter == null
                  ? null
                  : () => onAutomateParameter!('bcMode'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Row(children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Material(
                        color: i == selected
                            ? BitcrusherFxPanel.accent
                            : const Color(0xFF0C0C11),
                        child: InkWell(
                          key: ValueKey('bitcrusher-mode-$i'),
                          onTap: () =>
                              onParameterChanged('bcMode', i.toDouble()),
                          child: Container(
                            decoration: BoxDecoration(
                              border: i < labels.length - 1
                                  ? Border(
                                      right: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: .07)))
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(labels[i],
                                style: TextStyle(
                                    color: i == selected
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            );
          },
        ),
        const Spacer(),
        deviceAutomationSpinner(
          paramId: 'bcFilter',
          width: 120,
          height: 40,
          accentColor: BitcrusherFxPanel.accent,
          borderAlpha: 0,
          modulatedParams: modulatedParams,
          automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          child: PopupMenuButton<int>(
            padding: EdgeInsets.zero,
            color: const Color(0xFF22222E),
            onSelected: (value) =>
                onParameterChanged('bcFilter', const [1.0, .7, .4][value]),
            itemBuilder: (_) => [
              for (var i = 0; i < 3; i++)
                PopupMenuItem<int>(
                  value: i,
                  height: 32,
                  child: Text(const ['Off', 'Soft', 'Steep'][i],
                      style: TextStyle(
                        fontSize: 10,
                        color: i == antiAlias
                            ? BitcrusherFxPanel.accent
                            : Colors.white70,
                      )),
                ),
            ],
            child: const Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('ANTI-ALIAS',
                    style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white60,
                        fontWeight: FontWeight.w700)),
                SizedBox(width: 1),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14, color: Colors.white54),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
