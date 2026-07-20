part of '../dynamics_fx_panels.dart';

/// Face layout from `daw_elements.svg` → `ducker_device`:
/// left SC rail (FX + meter + Gain) | right 2×2 duck knobs.
class DuckerDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['ducker'];
  const DuckerDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
    this.audioFxExpanded = false,
    this.onToggleAudioFx,
  });

  static const accent = Color(0xFFF472B6);
  static const containerTabs = <DeviceTabSpec>[];

  /// Matches SVG tab-bar width (~271).
  static const double designWidth = 271;
  static const double _scRailWidth = 76;

  final DuckerDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final bool audioFxExpanded;
  final VoidCallback? onToggleAudioFx;

  _DynamicsKnob _k({
    required String label,
    required double value,
    required String paramId,
    String? displayValue,
  }) {
    return _knob(
      label: label,
      value: value,
      paramId: paramId,
      accent: accent,
      onParameterChanged: onParameterChanged,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      deviceId: device.id,
      lfos: lfos,
      modEdges: modEdges,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
      displayValue: displayValue,
    );
  }

  BoxDecoration get _wellDecoration => BoxDecoration(
        color: DeviceStripTheme.panelElevated,
        borderRadius: BorderRadius.circular(4),
      );

  Widget _scRail() {
    final level = device.meterInputLevel.clamp(0.0, 1.0);
    final visible = level <= 0.001 ? 0.0 : level.clamp(0.05, 1.0);
    return DecoratedBox(
      decoration: _wellDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        child: Column(
          children: [
            _DuckerScFxToggle(
              active: audioFxExpanded,
              onPressed: onToggleAudioFx,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 16,
                  child: ColoredBox(
                    color: DeviceStripTheme.panelScreen,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: visible,
                        widthFactor: 1,
                        child: ColoredBox(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _k(
              label: 'Gain',
              value: device.sidechainGain,
              paramId: 'sidechainGain',
              displayValue: StereoGainPanPanel.formatGain(device.sidechainGain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _duckWell() {
    return DecoratedBox(
      decoration: _wellDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _k(
                  label: 'Threshold',
                  value: device.duckThreshold,
                  paramId: 'duckThreshold',
                  displayValue: dynamicsThresholdLabel(device.duckThreshold),
                ),
                _k(
                  label: 'Depth',
                  value: device.duckDepth,
                  paramId: 'duckDepth',
                  displayValue: '${(device.duckDepth * 100).round()}%',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _k(
                  label: 'Attack',
                  value: device.duckAttack,
                  paramId: 'duckAttack',
                  displayValue: dynamicsTimeLabel(device.duckAttack),
                ),
                _k(
                  label: 'Release',
                  value: device.duckRelease,
                  paramId: 'duckRelease',
                  displayValue: dynamicsTimeLabel(device.duckRelease),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: _scRailWidth, child: _scRail()),
          const SizedBox(width: 6),
          Expanded(child: _duckWell()),
        ],
      ),
    );
  }
}

/// Chrome-sized FX toggle (matches SVG `audio_fx_button` / `_FxToggleButton`).
class _DuckerScFxToggle extends StatelessWidget {
  const _DuckerScFxToggle({
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback? onPressed;

  static const _accent = Color(0xFF00FF33);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 55,
        height: 25,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: 55,
              height: 25,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF222229),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child: Text(
                    'SC FX',
                    style: TextStyle(
                      color: Color(0xFFF2F2F2),
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: 3,
              child: CustomPaint(
                painter: _DuckerScFxBracketPainter(active: active),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuckerScFxBracketPainter extends CustomPainter {
  const _DuckerScFxBracketPainter({required this.active});

  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _DuckerScFxToggle._accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DuckerScFxBracketPainter old) => old.active != active;
}
