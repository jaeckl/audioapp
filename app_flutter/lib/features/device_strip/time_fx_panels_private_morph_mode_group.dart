part of 'time_fx_panels.dart';

class _MorphModeGroup extends StatefulWidget {
  const _MorphModeGroup({
    required this.labels,
    required this.keyPrefix,
    required this.value,
    required this.accent,
    required this.modulationActive,
    required this.modulationAmount,
    required this.automationActive,
    required this.connectModeActive,
    required this.linkModeActive,
    required this.onChanged,
    this.onModulationAssign,
    this.onAutomationLinkTap,
    this.onAutomateRequest,
  });

  final List<String> labels;
  final String keyPrefix;
  final double value;
  final Color accent;
  final bool modulationActive;
  final double modulationAmount;
  final bool automationActive;
  final bool connectModeActive;
  final bool linkModeActive;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onModulationAssign;
  final VoidCallback? onAutomationLinkTap;
  final VoidCallback? onAutomateRequest;

  @override
  State<_MorphModeGroup> createState() => _MorphModeGroupState();
}
