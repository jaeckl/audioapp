part of 'mood_fx_panels.dart';

class _HorizontalGroupShell extends StatefulWidget {
  const _HorizontalGroupShell({
    required this.width,
    required this.height,
    required this.value,
    required this.maxValue,
    required this.accent,
    required this.modulationActive,
    required this.modulationAmount,
    required this.automationActive,
    required this.connectModeActive,
    required this.linkModeActive,
    required this.child,
    this.onModulationAssign,
    this.onLinkTap,
    this.onAutomateRequest,
  });

  final double width, height, value, maxValue, modulationAmount;
  final Color accent;
  final bool modulationActive, automationActive;
  final bool connectModeActive, linkModeActive;
  final Widget child;
  final ValueChanged<double>? onModulationAssign;
  final VoidCallback? onLinkTap, onAutomateRequest;

  @override
  State<_HorizontalGroupShell> createState() => _HorizontalGroupShellState();
}
