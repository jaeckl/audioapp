part of 'mixer_view.dart';

class _StereoMeter extends StatelessWidget {
  const _StereoMeter({required this.left, required this.right});
  final double left, right;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 14,
        child: Row(children: [
          _bar(left),
          const SizedBox(width: 2),
          _bar(right),
        ]),
      );

  Widget _bar(double value) => Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final level = math.sqrt(value.clamp(0.0, 1.0));
            final color = value >= 1
                ? Colors.redAccent
                : value > .72
                    ? Colors.amber
                    : const Color(0xFF65D68B);
            return Stack(alignment: Alignment.bottomCenter, children: [
              Container(color: Colors.black38),
              FractionallySizedBox(
                heightFactor: level,
                child: Container(color: color),
              ),
            ]);
          },
        ),
      );
}
