import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_landscape_shell.dart';
import 'device_strip_metrics.dart';
import 'sampler_device_panel.dart';
import 'waveform_trim_editor.dart';

/// Fullscreen sampler editor — landscape, tabbed device with large knobs.
class SamplerEditorScreen extends StatefulWidget {
  const SamplerEditorScreen({
    super.key,
    required this.trackName,
    required this.device,
    required this.sample,
    required this.bpm,
    required this.onParameterChanged,
    required this.onLoadSample,
  });

  final String trackName;
  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final int bpm;
  final Future<void> Function(String parameterId, double value) onParameterChanged;
  final Future<SampleLibraryEntrySnapshot?> Function() onLoadSample;

  @override
  State<SamplerEditorScreen> createState() => _SamplerEditorScreenState();
}

class _SamplerEditorScreenState extends State<SamplerEditorScreen> {
  late DeviceSnapshot _device;
  SampleLibraryEntrySnapshot? _sample;
  SamplerDeviceTab _tab = SamplerDeviceTab.sample;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    _sample = widget.sample;
  }

  double get _durationSec {
    final beats = _sample?.durationBeats ?? 0;
    if (beats <= 0 || widget.bpm <= 0) return 1.0;
    return beats * 60.0 / widget.bpm;
  }

  Future<void> _handleParameterChanged(String parameterId, double value) async {
    setState(() => _device = _device.withParameter(parameterId, value));
    await widget.onParameterChanged(parameterId, value);
  }

  Future<void> _handleLoadSample() async {
    final sample = await widget.onLoadSample();
    if (!mounted || sample == null) {
      return;
    }
    setState(() {
      _sample = sample;
      _device = _device.copyWith(sampleId: sample.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sampleName = _sample?.name ?? 'No sample loaded';
    final peaks = _sample?.waveformPeaks ?? const <double>[];

    return DeviceLandscapeShell(
      title: '${widget.trackName} · $sampleName',
      designWidth: DeviceStripMetrics.designWidth,
      designHeight: DeviceStripMetrics.height + 40,
      actions: [
        IconButton(
          tooltip: 'Load sample',
          onPressed: _handleLoadSample,
          icon: const Icon(Icons.folder_open_outlined),
        ),
      ],
      child: Column(
        children: [
          if (_tab == SamplerDeviceTab.sample)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: peaks.isEmpty
                    ? const Center(child: Text('Load a sample to trim'))
                    : WaveformTrimEditor(
                        peaks: peaks,
                        durationSec: _durationSec,
                        trimStartSec: _device.trimStartSec,
                        trimEndSec: _device.trimEndSec,
                        onTrimChanged: (start, end) async {
                          await _handleParameterChanged('trimStartSec', start);
                          await _handleParameterChanged('trimEndSec', end);
                        },
                      ),
              ),
            ),
          Expanded(
            flex: _tab == SamplerDeviceTab.sample ? 3 : 5,
            child: SamplerDevicePanel(
              device: _device,
              sample: _sample,
              initialTab: _tab,
              density: SamplerPanelDensity.editor,
              onTabChanged: (tab) => setState(() => _tab = tab),
              onParameterChanged: (parameterId, value) {
                _handleParameterChanged(parameterId, value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
