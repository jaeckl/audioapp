part of 'subtractive_synth_presets.dart';

class SubtractivePresetMod {
  const SubtractivePresetMod({
    required this.lfoIndex,
    required this.paramId,
    required this.amount,
  });

  final int lfoIndex;
  final String paramId;
  final double amount;

  Map<String, dynamic> toJson() => {
        'lfoIndex': lfoIndex,
        'paramId': paramId,
        'amount': amount,
      };
}
