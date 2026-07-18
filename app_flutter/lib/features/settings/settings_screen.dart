import 'package:flutter/material.dart';

import '../welcome/welcome_theme.dart';
import 'audio_engine_settings.dart';

/// App-level preferences. Project and transport state do not belong here.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.showWelcomeOnLaunch,
    required this.onShowWelcomeOnLaunchChanged,
    this.audioEngineProfile = AudioEngineProfile.balanced,
    this.audioEngineStatus,
    this.onAudioEngineProfileChanged,
  });

  final bool showWelcomeOnLaunch;
  final Future<void> Function(bool value) onShowWelcomeOnLaunchChanged;
  final AudioEngineProfile audioEngineProfile;
  final AudioEngineStatus? audioEngineStatus;
  final Future<AudioEngineStatus> Function(AudioEngineProfile profile)?
      onAudioEngineProfileChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showWelcomeOnLaunch = widget.showWelcomeOnLaunch;
  late AudioEngineProfile _audioEngineProfile = widget.audioEngineProfile;
  late AudioEngineStatus? _audioEngineStatus = widget.audioEngineStatus;
  bool _saving = false;
  bool _savingAudio = false;
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

  Future<void> _setAudioEngineProfile(AudioEngineProfile profile) async {
    final callback = widget.onAudioEngineProfileChanged;
    if (_savingAudio || profile == _audioEngineProfile || callback == null) {
      return;
    }
    final previous = _audioEngineProfile;
    setState(() {
      _audioEngineProfile = profile;
      _savingAudio = true;
      _error = null;
    });
    try {
      final status = await callback(profile);
      if (!mounted) return;
      setState(() => _audioEngineStatus = status);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _audioEngineProfile = previous;
        _error = error.toString();
      });
    } finally {
      if (mounted) setState(() => _savingAudio = false);
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
            const Text('AUDIO ENGINE', style: WelcomeTheme.sectionLabel),
            const SizedBox(height: 10),
            Material(
              color: WelcomeTheme.panelBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WelcomeTheme.panelRadius),
                side: const BorderSide(color: WelcomeTheme.panelBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final profile in AudioEngineProfile.values)
                    InkWell(
                      key: ValueKey('settings-audio-${profile.storageValue}'),
                      onTap: _savingAudio
                          ? null
                          : () => _setAudioEngineProfile(profile),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              profile == _audioEngineProfile
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: profile == _audioEngineProfile
                                  ? WelcomeTheme.accent
                                  : WelcomeTheme.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.label,
                                    style: const TextStyle(
                                      color: WelcomeTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.description,
                                    style: const TextStyle(
                                      color: WelcomeTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_savingAudio)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: WelcomeTheme.accent,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _AudioEngineDiagnostics(status: _audioEngineStatus),
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

class _AudioEngineDiagnostics extends StatelessWidget {
  const _AudioEngineDiagnostics({required this.status});

  final AudioEngineStatus? status;

  @override
  Widget build(BuildContext context) {
    final current = status;
    final values = current == null
        ? const [('Engine', 'Status available after native startup')]
        : <(String, String)>[
            ('Backend', current.platform),
            ('Stream', current.streamOpen ? 'Open' : 'Idle'),
            ('Sample rate', '${current.sampleRate.round()} Hz'),
            if (current.framesPerBurst > 0)
              ('Hardware burst', '${current.framesPerBurst} frames'),
            if (current.bufferSizeFrames > 0)
              ('Active buffer', '${current.bufferSizeFrames} frames'),
            ('Mode', '${current.performanceMode} · ${current.sharingMode}'),
            ('AAudio XRuns', '${current.xRunCount}'),
            ('DSP deadline misses', '${current.callbackOverruns}'),
          ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WelcomeTheme.panelBackground,
        borderRadius: BorderRadius.circular(WelcomeTheme.panelRadius),
        border: Border.all(color: WelcomeTheme.panelBorder),
      ),
      child: Column(
        children: [
          for (var index = 0; index < values.length; index++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    values[index].$1,
                    style: const TextStyle(color: WelcomeTheme.textMuted),
                  ),
                ),
                Text(
                  values[index].$2,
                  style: const TextStyle(
                    color: WelcomeTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (index != values.length - 1) const SizedBox(height: 7),
          ],
        ],
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
