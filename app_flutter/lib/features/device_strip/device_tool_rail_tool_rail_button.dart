part of 'device_tool_rail.dart';

class _ToolRailButton extends StatefulWidget {
  const _ToolRailButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = true,
    this.enabled = true,
    this.modulationActive = false,
    this.automationActive = false,
    this.connectModeActive = false,
    this.linkModeActive = false,
    this.onModulationAssign,
    this.onLinkTap,
    this.onAutomateRequest,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final bool enabled;
  final bool modulationActive;
  final bool automationActive;
  final bool connectModeActive;
  final bool linkModeActive;
  final ValueChanged<double>? onModulationAssign;
  final VoidCallback? onLinkTap;
  final VoidCallback? onAutomateRequest;

  @override
  State<_ToolRailButton> createState() => _ToolRailButtonState();
}
