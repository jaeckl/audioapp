import 'package:flutter/material.dart';

import '../welcome/welcome_theme.dart';

/// App-level preferences. Project and transport state do not belong here.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.showWelcomeOnLaunch,
    required this.onShowWelcomeOnLaunchChanged,
  });

  final bool showWelcomeOnLaunch;
  final Future<void> Function(bool value) onShowWelcomeOnLaunchChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showWelcomeOnLaunch = widget.showWelcomeOnLaunch;
  bool _saving = false;
  String? _error;

  Future<void> _setShowWelcomeOnLaunch(bool value) async {
    if (_saving) return;
    setState(() {
      _showWelcomeOnLaunch = value;
      _saving = true;
      _error = null;
    });
    try {
      await widget.onShowWelcomeOnLaunchChanged(value);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _showWelcomeOnLaunch = !value;
        _error = error.toString();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WelcomeTheme.background,
      appBar: AppBar(
        backgroundColor: WelcomeTheme.background,
        foregroundColor: WelcomeTheme.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const _SettingsHeader(),
            const SizedBox(height: WelcomeTheme.sectionGap),
            const Text('STARTUP', style: WelcomeTheme.sectionLabel),
            const SizedBox(height: 10),
            Material(
              color: WelcomeTheme.panelBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WelcomeTheme.panelRadius),
                side: const BorderSide(color: WelcomeTheme.panelBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                key: const ValueKey('settings-show-welcome'),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                activeThumbColor: WelcomeTheme.accent,
                title: const Text(
                  'Show project hub on launch',
                  style: TextStyle(
                    color: WelcomeTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _saving
                      ? 'Saving…'
                      : 'Choose a recent, new, or existing project when AudioApp starts',
                  style: const TextStyle(color: WelcomeTheme.textMuted),
                ),
                value: _showWelcomeOnLaunch,
                onChanged: _saving ? null : _setShowWelcomeOnLaunch,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: WelcomeTheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'App preferences are saved automatically. Loop playback stays with the project and is controlled from the transport.',
              style: TextStyle(color: WelcomeTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: WelcomeTheme.accentSoft,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              Icons.settings_rounded,
              size: 27,
              color: WelcomeTheme.accent,
            ),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App settings',
                style: TextStyle(
                  color: WelcomeTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Preferences that persist across projects',
                style: TextStyle(color: WelcomeTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
