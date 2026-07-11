part of 'sampler_waveform_view.dart';

class _Handle extends StatelessWidget {
  const _Handle({
    required this.left,
    required this.top,
    required this.bottom,
    required this.color,
    required this.alignLeft,
  });

  final double left;
  final double top;
  final double bottom;
  final Color color;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: _SamplerWaveformViewState._handleVisualWidth,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: alignLeft ? Radius.zero : const Radius.circular(3),
              bottomLeft: alignLeft ? Radius.zero : const Radius.circular(3),
              topRight: alignLeft ? const Radius.circular(3) : Radius.zero,
              bottomRight: alignLeft ? const Radius.circular(3) : Radius.zero,
            ),
            border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 2,
                  offset: Offset(0, 1)),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.drag_handle,
              size: 12,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}
