part of 'sampler_waveform_view.dart';

class _SamplerFineTuneChipState extends State<SamplerFineTuneChip> {
  double _dragStartY = 0;
  double _dragStartCents = 0;

  void _bump(int delta) {
    final next = (widget.rootFineTune + delta).clamp(-100.0, 100.0);
    if (next != widget.rootFineTune) {
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mod = widget.modulation;
    return EffectiveParameterValueBuilder(
      parameterId: 'rootFineTune',
      fallbackValue: (widget.rootFineTune + 100) / 200,
      active: mod.automatedParams.contains('rootFineTune'),
      builder: (context, liveValue) =>
          _buildWithFineTune(context, liveValue * 200 - 100),
    );
  }

  Widget _buildWithFineTune(BuildContext context, double displayedFineTune) {
    final label = formatSamplerFineTune(displayedFineTune);
    final accent = widget.accentColor;
    final muted = accent.withValues(alpha: 0.55);

    final noteLabel = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (d) {
        _dragStartY = d.localPosition.dy;
        _dragStartCents = widget.rootFineTune;
      },
      onVerticalDragUpdate: (d) {
        final delta = ((_dragStartY - d.localPosition.dy) / 4).round();
        final next = (_dragStartCents + delta).clamp(-100.0, 100.0);
        if (next != widget.rootFineTune) {
          widget.onChanged(next);
        }
      },
      onDoubleTap: () => widget.onChanged(0),
      child: Text(
        label,
        style: TextStyle(
          color: accent.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );

    final inner = widget.fixedHeight != null
        ? Column(
            children: [
              Expanded(
                child: _RootStepHit(
                  icon: Icons.keyboard_arrow_up_rounded,
                  color: muted,
                  onTap: () => _bump(1),
                  expand: true,
                ),
              ),
              noteLabel,
              Expanded(
                child: _RootStepHit(
                  icon: Icons.keyboard_arrow_down_rounded,
                  color: muted,
                  onTap: () => _bump(-1),
                  expand: true,
                ),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RootStepHit(
                icon: Icons.keyboard_arrow_up_rounded,
                color: muted,
                onTap: () => _bump(1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: noteLabel,
              ),
              _RootStepHit(
                icon: Icons.keyboard_arrow_down_rounded,
                color: muted,
                onTap: () => _bump(-1),
              ),
            ],
          );

    if (widget.fixedHeight != null) {
      final mod = widget.modulation;
      return deviceAutomationSpinner(
        paramId: 'rootFineTune',
        width: 40,
        height: widget.fixedHeight!,
        accentColor: accent,
        borderAlpha: 0.35,
        modulatedParams: mod.modulatedParams,
        automatedParams: mod.automatedParams,
        modulationAmounts: mod.modulationAmounts,
        modulatorPolarity: mod.rootFineTunePolarity,
        connectModeLfoId: mod.connectModeLfoId,
        onModulationAssign: mod.onModulationAssign,
        automationLinkActive: mod.automationLinkActive,
        onAutomationLinkTap: mod.onAutomationLinkTap,
        onAutomateParameter: mod.onAutomateParameter,
        child: inner,
      );
    }

    return Container(
      width: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF14141C),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: inner,
    );
  }
}
