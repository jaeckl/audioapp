part of 'sample_editor_screen.dart';

class _ClipEditPanel extends StatelessWidget {
  const _ClipEditPanel({
    required this.tool,
    required this.gain,
    required this.start,
    required this.end,
    required this.fadeIn,
    required this.fadeOut,
    required this.fadeInCurve,
    required this.fadeOutCurve,
    required this.onGainChanged,
    required this.onCurveChanged,
  });
  final _SampleTool tool;
  final double gain, start, end, fadeIn, fadeOut, fadeInCurve, fadeOutCurve;
  final ValueChanged<double> onGainChanged;
  final void Function(double, double) onCurveChanged;

  ({String title, String hint}) get _copy => switch (tool) {
        _SampleTool.navigate => (
            title: 'TIMELINE',
            hint: 'PINCH TO ZOOM  •  DRAG TO PAN',
          ),
        _SampleTool.trim => (
            title: 'TRIM BOUNDS',
            hint: 'DRAG START AND END HANDLES',
          ),
        _SampleTool.fade => (
            title: 'FADE ENVELOPE',
            hint: 'DRAG FADE HANDLES ON WAVEFORM',
          ),
        _ => (title: 'CLIP EDITOR', hint: ''),
      };

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ToolCardHeader(title: copy.title, hint: copy.hint),
        Expanded(
            child: tool == _SampleTool.fade ? _fadeBody() : _defaultBody()),
      ],
    );
  }

  Widget _defaultBody() => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 68,
            child: Center(
              child: RotaryKnob(
                label: 'GAIN',
                value: (gain / 4).clamp(0, 1),
                size: 56,
                accentColor: AutomationEditorTheme.accent,
                displayValue: '${(gain * 100).round()}%',
                onChanged: (value) => onGainChanged(value * 4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ProcessGroup(
              title: 'BOUNDS',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InlineReadout(
                          label: 'START', value: '${(start * 100).round()}%'),
                    ),
                    Expanded(
                      child: _InlineReadout(
                          label: 'END', value: '${(end * 100).round()}%'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ProcessGroup(
              title: 'FADES',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InlineReadout(
                          label: 'FADE IN',
                          value: '${(fadeIn * 100).round()}%'),
                    ),
                    Expanded(
                      child: _InlineReadout(
                          label: 'FADE OUT',
                          value: '${(fadeOut * 100).round()}%'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _fadeBody() => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FadeCurveSelector(
              label: 'Fade In',
              percent: fadeIn,
              value: _FadeCurveKindX.fromValue(fadeInCurve),
              fadeOut: false,
              onChanged: (kind) => onCurveChanged(kind.value, fadeOutCurve),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FadeCurveSelector(
              label: 'Fade Out',
              percent: fadeOut,
              value: _FadeCurveKindX.fromValue(fadeOutCurve),
              fadeOut: true,
              onChanged: (kind) => onCurveChanged(fadeInCurve, kind.value),
            ),
          ),
        ],
      );
}
