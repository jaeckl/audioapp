part of 'bass_synth_device_panel.dart';

extension _BassSynthDevicePanelStateIntoctaveslot
    on _BassSynthDevicePanelState {
  Widget _intOctaveSlot({
    required int value,
    required String paramId,
    required int min,
    required int max,
    required String label,
    required String Function(int) formatter,
  }) {
    return EffectiveParameterValueBuilder(
      parameterId: paramId,
      fallbackValue: (value - min) / (max - min),
      active: widget.automatedParams.contains(paramId),
      builder: (context, liveValue) => _buildIntOctaveSlot(
        value: value,
        displayedValue: min + (liveValue * (max - min)).round(),
        paramId: paramId,
        min: min,
        max: max,
        label: label,
        formatter: formatter,
      ),
    );
  }

  Widget _buildIntOctaveSlot({
    required int value,
    required int displayedValue,
    required String paramId,
    required int min,
    required int max,
    required String label,
    required String Function(int) formatter,
  }) {
    final display = formatter(displayedValue);
    final accent = BassSynthDevicePanel.accent;
    final muted = accent.withValues(alpha: 0.55);
    final size = _knobSize;
    // Mirror RotaryKnob: labelSize = size >= 56 ? 10 : 9
    final labelSize = size >= DeviceKnobSizes.strip ? 10.0 : 9.0;

    void bump(int delta) {
      final next = (value + delta).clamp(min, max);
      if (next != value) {
        widget.onParameterChanged(paramId, next.toDouble());
      }
    }

    final inner = Column(
      children: [
        Expanded(
          child: _StepButton(
            icon: Icons.keyboard_arrow_up_rounded,
            color: muted,
            onTap: () => bump(1),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) {
            _octDragStartY = d.localPosition.dy;
            _octDragStartValue = value;
          },
          onVerticalDragUpdate: (d) {
            final delta = ((_octDragStartY - d.localPosition.dy) / 8).round();
            final next = (_octDragStartValue + delta).clamp(min, max);
            if (next != value) {
              widget.onParameterChanged(paramId, next.toDouble());
            }
          },
          onDoubleTap: () => widget.onParameterChanged(paramId, 0.toDouble()),
          child: Text(
            display,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
        Expanded(
          child: _StepButton(
            icon: Icons.keyboard_arrow_down_rounded,
            color: muted,
            onTap: () => bump(-1),
          ),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Spinner shell at size+4 to match RotaryKnob SizedBox height
        deviceAutomationSpinner(
          paramId: paramId,
          width: 46,
          height: size + 4,
          accentColor: accent,
          borderAlpha: 0.35,
          child: inner,
          modulatedParams: widget.modulatedParams,
          automatedParams: widget.automatedParams,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
          automationLinkActive: widget.automationLinkActive,
          onAutomationLinkTap: widget.onAutomationLinkTap,
          onAutomateParameter: widget.onAutomateParameter,
        ),
        const SizedBox(height: 3), // matches RotaryKnob.labelGap default
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
