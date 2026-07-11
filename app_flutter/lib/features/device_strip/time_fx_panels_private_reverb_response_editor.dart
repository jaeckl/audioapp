part of 'time_fx_panels.dart';

class _ReverbResponseEditor extends StatefulWidget {
  const _ReverbResponseEditor({
    required this.device,
    required this.view,
    required this.accent,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeActive,
    required this.linkModeActive,
    this.onModulationAssign,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final ReverbDeviceSnapshot device;
  final ReverbViewTab view;
  final Color accent;
  final TimeFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final bool connectModeActive;
  final bool linkModeActive;
  final TimeFxModulationAssign onModulationAssign;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  State<_ReverbResponseEditor> createState() => _ReverbResponseEditorState();
}
