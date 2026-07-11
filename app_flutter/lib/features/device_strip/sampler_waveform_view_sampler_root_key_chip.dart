part of 'sampler_waveform_view.dart';

class SamplerRootKeyChip extends StatefulWidget {
  const SamplerRootKeyChip({
    super.key,
    required this.rootPitch,
    required this.accentColor,
    required this.onChanged,
    this.showFooterLabel = true,
    this.fixedHeight,
    this.modulation = SpinnerModulationProps.none,
  });

  final int rootPitch;
  final Color accentColor;
  final ValueChanged<int> onChanged;
  final bool showFooterLabel;
  final double? fixedHeight;
  final SpinnerModulationProps modulation;

  @override
  State<SamplerRootKeyChip> createState() => _SamplerRootKeyChipState();
}
