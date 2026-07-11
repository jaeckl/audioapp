part of 'sample_editor_screen.dart';

class _ProcessPanelState extends State<_ProcessPanel> {
  _ProcessTab _tab = _ProcessTab.level;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ToolCardHeader(title: 'CLIP PROCESSING'),
          const SizedBox(height: 6),
          _ProcessTabBar(
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildTabBody()),
        ],
      );

  Widget _buildTabBody() => switch (_tab) {
        _ProcessTab.level => Center(
            child: RotaryKnob(
              label: 'GAIN',
              value: (widget.gain / 4).clamp(0, 1),
              size: 72,
              accentColor: AutomationEditorTheme.accent,
              displayValue: '${(widget.gain * 100).round()}%',
              onChanged: (value) => widget.onGainChanged(value * 4),
            ),
          ),
        _ProcessTab.playback => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniToggle(
                    label: 'Loop clip content',
                    active: widget.loop,
                    onTap: widget.onLoop),
                _MiniToggle(
                    label: 'Reverse playback',
                    active: widget.reversed,
                    onTap: widget.onReverse),
              ],
            ),
          ),
        _ProcessTab.warp => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniToggle(
                    label: 'Repitch to clip length',
                    active: widget.repitch,
                    onTap: widget.onRepitch),
                const SizedBox(height: 6),
                const _EngineField(),
                const SizedBox(height: 6),
                Text(
                  widget.repitch
                      ? 'Sample stretches to fit the clip on the timeline.'
                      : 'Sample plays at its natural speed and length.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9,
                      height: 1.35,
                      color: AutomationEditorTheme.labelMuted
                          .withValues(alpha: .9)),
                ),
              ],
            ),
          ),
        _ProcessTab.apply => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniToggle(
                  label: 'Normalize peak level',
                  icon: Icons.equalizer,
                  onTap: widget.onNormalize,
                ),
                const SizedBox(height: 8),
                Text(
                  'Scales gain so the loudest peak hits 0 dBFS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9,
                      height: 1.35,
                      color: AutomationEditorTheme.labelMuted
                          .withValues(alpha: .9)),
                ),
              ],
            ),
          ),
      };
}
