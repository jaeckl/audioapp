part of 'sampler_waveform_view.dart';

class SamplerFineTuneChip extends StatefulWidget {
  const SamplerFineTuneChip({
    super.key,
    required this.rootFineTune,
    required this.accentColor,
    required this.onChanged,
    this.fixedHeight,
    this.modulation = SpinnerModulationProps.none,
  });

  final double rootFineTune;
  final Color accentColor;
  final ValueChanged<double> onChanged;
  final double? fixedHeight;
  final SpinnerModulationProps modulation;

  @override
  State<SamplerFineTuneChip> createState() => _SamplerFineTuneChipState();
}
