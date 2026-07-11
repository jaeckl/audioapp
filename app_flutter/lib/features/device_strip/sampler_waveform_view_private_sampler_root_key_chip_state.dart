part of 'sampler_waveform_view.dart';

class _SamplerRootKeyChipState extends State<SamplerRootKeyChip> {
  double _dragStartY = 0;
  int _dragStartPitch = 60;

  void _bump(int delta) {
    final next = (widget.rootPitch + delta).clamp(0, 127);
    if (next != widget.rootPitch) {
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = formatSamplerMidiNote(widget.rootPitch);
    final accent = widget.accentColor;
    final muted = accent.withValues(alpha: 0.55);
    final mod = widget.modulation;

    final noteLabel = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (d) {
        _dragStartY = d.localPosition.dy;
        _dragStartPitch = widget.rootPitch;
      },
      onVerticalDragUpdate: (d) {
        final delta = ((_dragStartY - d.localPosition.dy) / 8).round();
        final next = (_dragStartPitch + delta).clamp(0, 127);
        if (next != widget.rootPitch) {
          widget.onChanged(next);
        }
      },
      onDoubleTap: () => widget.onChanged(60),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );

    Widget inner = widget.fixedHeight != null
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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: noteLabel,
              ),
              _RootStepHit(
                icon: Icons.keyboard_arrow_down_rounded,
                color: muted,
                onTap: () => _bump(-1),
              ),
            ],
          );

    Widget box;
    if (widget.fixedHeight != null) {
      box = deviceAutomationSpinner(
        paramId: 'rootPitch',
        width: 46,
        height: widget.fixedHeight!,
        accentColor: accent,
        borderAlpha: 0.5,
        modulatedParams: mod.modulatedParams,
        automatedParams: mod.automatedParams,
        modulationAmounts: mod.modulationAmounts,
        modulatorPolarity: mod.rootPitchPolarity,
        connectModeLfoId: mod.connectModeLfoId,
        onModulationAssign: mod.onModulationAssign,
        automationLinkActive: mod.automationLinkActive,
        onAutomationLinkTap: mod.onAutomationLinkTap,
        onAutomateParameter: mod.onAutomateParameter,
        child: inner,
      );
    } else {
      box = Container(
        width: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: inner,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        box,
        if (widget.showFooterLabel) ...[
          const SizedBox(height: 2),
          Text(
            'ROOT',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}
