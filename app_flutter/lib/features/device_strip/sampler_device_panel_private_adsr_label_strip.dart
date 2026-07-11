part of 'sampler_device_panel.dart';

class _AdsrLabelStrip extends StatelessWidget {
  const _AdsrLabelStrip({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
