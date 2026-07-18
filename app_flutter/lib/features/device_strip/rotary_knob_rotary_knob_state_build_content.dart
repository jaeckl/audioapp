part of 'rotary_knob.dart';

extension RotaryKnobStateBuildcontentOperation on _RotaryKnobState {
  Widget _buildContent(BuildContext context) {
    final stroke = widget.size >= DeviceKnobSizes.editor ? 4.0 : 3.0;
    final theme = Theme.of(context);
    final displayValue = _displayValue;
    final angle = KnobArcGeometry.indicatorAngle(displayValue);
    final labelSize = widget.size >= DeviceKnobSizes.strip ? 10.0 : 9.0;
    final pulseAccent =
        widget.linkModeActive ? widget.linkModeAccent : widget.accentColor;
    final showConnectPulse =
        (widget.connectModeActive || widget.linkModeActive) &&
            _highlightsVisible;
    final effectivePolarity =
        widget.polarityParamId != null && widget.deviceId != null
            ? modulatorPolarityForParam(
                paramId: widget.polarityParamId!,
                deviceId: widget.deviceId!,
                modEdges: widget.modEdges,
                lfos: widget.lfos,
                connectModeLfoId:
                    widget.connectModeActive ? widget.connectModeLfoId : null,
              )
            : widget.modulatorPolarity;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.linkModeActive && widget.onLinkTap != null
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onLinkTap!.call();
                }
              : null,
          onLongPress: widget.linkModeActive || !widget.connectModeActive
              ? _onLongPress
              : null,
          onLongPressStart: widget.connectModeActive ? _onLongPressStart : null,
          onLongPressMoveUpdate:
              widget.connectModeActive ? _onLongPressMoveUpdate : null,
          onLongPressEnd: widget.connectModeActive ? _onLongPressEnd : null,
          onVerticalDragStart: widget.linkModeActive ? null : _onDragStart,
          onVerticalDragUpdate: widget.linkModeActive ? null : _onDragUpdate,
          onVerticalDragEnd: widget.linkModeActive ? null : _onDragEnd,
          onVerticalDragCancel: widget.linkModeActive ? null : _onDragCancel,
          onDoubleTap: () => widget.onChanged(0.5),
          child: SizedBox(
            width: widget.size + 8,
            height: widget.size + 4,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final showGlow = showConnectPulse;
                return CustomPaint(
                  painter: showGlow
                      ? _BackgroundGlowPainter(
                          glowColor: pulseAccent.withValues(
                              alpha: _pulseAnimation.value),
                          borderRadius: 8,
                          center: KnobArcGeometry.visualCenterInCenteredHost(
                            knobSize: widget.size,
                            hostSize: Size(widget.size + 8, widget.size + 4),
                          ),
                        )
                      : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: _KnobPainter(
                            value: displayValue.clamp(0, 1),
                            angle: angle,
                            accentColor: pulseAccent,
                            strokeWidth: stroke,
                            modulationActive: widget.modulationActive,
                            modulationAmount: widget.modulationAmount,
                            modulatorPolarity: effectivePolarity,
                            connectModeActive: showConnectPulse,
                            assignmentMode: _assignmentMode,
                            assignmentAmount: _assignmentAmount,
                          ),
                        ),
                      ),
                      if (widget.automationActive)
                        Positioned(
                          top: 0,
                          right: 4,
                          child: IgnorePointer(
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB48CFF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF14141C),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB48CFF)
                                        .withValues(alpha: 0.7),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (widget.displayValue != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.displayValue!,
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: widget.accentColor,
                                fontSize: widget.size * 0.17,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.showLabel) ...[
          SizedBox(height: widget.labelGap),
          if (widget.labelOptions.isEmpty)
            SizedBox(
              width: widget.size + 8,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              key: ValueKey('knob-label-menu-${widget.label}'),
              tooltip: 'Select ${widget.label} mode',
              initialValue: widget.label,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 96),
              color: const Color(0xFF22222E),
              onSelected: widget.onLabelOptionSelected,
              itemBuilder: (context) => widget.labelOptions
                  .map((option) => PopupMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
              child: SizedBox(
                width: widget.size + 8,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_left,
                          size: 10, color: Colors.white54),
                      Text(
                        widget.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontSize: labelSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 10, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
