import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../welcome/welcome_theme.dart';
import 'audio_engine_settings.dart';

/// App-level preferences. Project and transport state do not belong here.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.showWelcomeOnLaunch,
    required this.onShowWelcomeOnLaunchChanged,
    this.audioEngineProfile = AudioEngineProfile.balanced,
    this.customAudioSettings = const AudioEngineCustomSettings(),
    this.audioEngineStatus,
    this.onAudioEngineConfigurationChanged,
  });

  final bool showWelcomeOnLaunch;
  final Future<void> Function(bool value) onShowWelcomeOnLaunchChanged;
  final AudioEngineProfile audioEngineProfile;
  final AudioEngineCustomSettings customAudioSettings;
  final AudioEngineStatus? audioEngineStatus;
  final Future<AudioEngineStatus> Function(
    AudioEngineProfile profile,
    AudioEngineCustomSettings customSettings,
  )? onAudioEngineConfigurationChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _showWelcomeOnLaunch = widget.showWelcomeOnLaunch;
  late AudioEngineProfile _audioEngineProfile = widget.audioEngineProfile;
  late AudioEngineCustomSettings _customAudioSettings =
      widget.customAudioSettings;
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

  Future<void> _setAudioEngineConfiguration(
    AudioEngineProfile profile,
    AudioEngineCustomSettings customSettings,
  ) async {
    final callback = widget.onAudioEngineConfigurationChanged;
    if (_savingAudio || callback == null) {
      return;
    }
    if (profile == _audioEngineProfile &&
        profile != AudioEngineProfile.custom) {
      return;
    }
    if (profile == AudioEngineProfile.custom) customSettings.validate();
    final previous = _audioEngineProfile;
    setState(() {
      _audioEngineProfile = profile;
      _savingAudio = true;
      _error = null;
    });
    try {
      final status = await callback(profile, customSettings);
      if (!mounted) return;
      setState(() {
        _audioEngineStatus = status;
        _customAudioSettings = customSettings;
      });
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
                          : () => _setAudioEngineConfiguration(
                                profile,
                                _customAudioSettings,
                              ),
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
                  if (_audioEngineProfile == AudioEngineProfile.custom)
                    _CustomAudioControls(
                      initialSettings: _customAudioSettings,
                      actualBurstFrames:
                          _audioEngineStatus?.framesPerBurst ?? 0,
                      enabled: !_savingAudio,
                      onApply: (settings) => _setAudioEngineConfiguration(
                        AudioEngineProfile.custom,
                        settings,
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

class _CustomAudioControls extends StatefulWidget {
  const _CustomAudioControls({
    required this.initialSettings,
    required this.actualBurstFrames,
    required this.enabled,
    required this.onApply,
  });

  final AudioEngineCustomSettings initialSettings;
  final int actualBurstFrames;
  final bool enabled;
  final Future<void> Function(AudioEngineCustomSettings settings) onApply;

  @override
  State<_CustomAudioControls> createState() => _CustomAudioControlsState();
}

class _CustomAudioControlsState extends State<_CustomAudioControls> {
  late final TextEditingController _sampleRate = TextEditingController(
    text: '${widget.initialSettings.sampleRate}',
  );
  late final TextEditingController _callbackFrames = TextEditingController(
    text: '${widget.initialSettings.framesPerCallback}',
  );
  late final TextEditingController _bufferCapacity = TextEditingController(
    text: '${widget.initialSettings.bufferCapacityFrames}',
  );
  late final TextEditingController _bufferSize = TextEditingController(
    text: '${widget.initialSettings.bufferSizeFrames}',
  );
  late bool _lowLatency = widget.initialSettings.lowLatency;
  late bool _exclusive = widget.initialSettings.exclusive;
  String? _validationError;

  @override
  void dispose() {
    _sampleRate.dispose();
    _callbackFrames.dispose();
    _bufferCapacity.dispose();
    _bufferSize.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    try {
      final settings = AudioEngineCustomSettings(
        sampleRate: int.parse(_sampleRate.text.trim()),
        framesPerCallback: int.parse(_callbackFrames.text.trim()),
        bufferCapacityFrames: int.parse(_bufferCapacity.text.trim()),
        bufferSizeFrames: int.parse(_bufferSize.text.trim()),
        lowLatency: _lowLatency,
        exclusive: _exclusive,
      );
      settings.validate();
      setState(() => _validationError = null);
      await widget.onApply(settings);
    } on FormatException catch (error) {
      setState(() => _validationError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('settings-custom-audio-controls'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: WelcomeTheme.panelBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXPERT STREAM REQUEST',
            style: WelcomeTheme.sectionLabel,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AudioNumberField(
                  fieldKey: const ValueKey('settings-custom-sample-rate'),
                  controller: _sampleRate,
                  label: 'Sample rate',
                  suffix: 'Hz',
                  enabled: widget.enabled,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AudioNumberField(
                  fieldKey: const ValueKey('settings-custom-callback'),
                  controller: _callbackFrames,
                  label: 'Callback',
                  suffix: 'frames',
                  enabled: widget.enabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AudioNumberField(
                  fieldKey: const ValueKey('settings-custom-capacity'),
                  controller: _bufferCapacity,
                  label: 'Capacity',
                  suffix: 'frames',
                  enabled: widget.enabled,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AudioNumberField(
                  fieldKey: const ValueKey('settings-custom-buffer'),
                  controller: _bufferSize,
                  label: 'Active buffer',
                  suffix: 'frames',
                  enabled: widget.enabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: WelcomeTheme.accent,
            title: const Text('Low-latency performance mode'),
            value: _lowLatency,
            onChanged: widget.enabled
                ? (value) => setState(() => _lowLatency = value)
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: WelcomeTheme.accent,
            title: const Text('Request exclusive output'),
            subtitle: const Text(
              'Falls back to shared output if Android rejects the request',
              style: TextStyle(color: WelcomeTheme.textMuted),
            ),
            value: _exclusive,
            onChanged: widget.enabled
                ? (value) => setState(() => _exclusive = value)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            widget.actualBurstFrames > 0
                ? 'Hardware burst: ${widget.actualBurstFrames} frames (negotiated by Android)'
                : 'Hardware burst is negotiated by Android and appears after playback starts.',
            style: const TextStyle(
              color: WelcomeTheme.textMuted,
              fontSize: 12,
            ),
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _validationError!,
              style: const TextStyle(color: WelcomeTheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('settings-apply-custom-audio'),
              onPressed: widget.enabled ? _apply : null,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Apply custom audio settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioNumberField extends StatelessWidget {
  const _AudioNumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.enabled,
  });

  final TextEditingController controller;
  final Key fieldKey;
  final String label;
  final String suffix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
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
            if (current.framesPerCallback > 0)
              ('Callback', '${current.framesPerCallback} frames'),
            if (current.framesPerBurst > 0)
              ('Hardware burst', '${current.framesPerBurst} frames'),
            if (current.bufferSizeFrames > 0)
              ('Active buffer', '${current.bufferSizeFrames} frames'),
            if (current.bufferCapacityFrames > 0)
              ('Buffer capacity', '${current.bufferCapacityFrames} frames'),
            if (current.profile == AudioEngineProfile.custom) ...[
              ('Requested rate', '${current.requestedSampleRate} Hz'),
              (
                'Requested callback',
                '${current.requestedFramesPerCallback} frames'
              ),
              (
                'Requested buffer',
                '${current.requestedBufferSizeFrames} / ${current.requestedBufferCapacityFrames} frames'
              ),
            ],
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
