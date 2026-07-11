part of 'mood_fx_panels.dart';

class _StutterHoldButton extends StatefulWidget {
  const _StutterHoldButton({
    required this.active,
    required this.automationActive,
    required this.linkModeActive,
    required this.modulationActive,
    required this.modulationAmount,
    required this.connectModeActive,
    required this.accent,
    required this.onTap,
    this.onAutomationLinkTap,
    this.onAutomateRequest,
    this.onModulationAssign,
  });

  final bool active;
  final bool automationActive;
  final bool linkModeActive;
  final bool modulationActive;
  final double modulationAmount;
  final bool connectModeActive;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onAutomationLinkTap;
  final VoidCallback? onAutomateRequest;
  final ValueChanged<double>? onModulationAssign;

  @override
  State<_StutterHoldButton> createState() => _StutterHoldButtonState();
}
