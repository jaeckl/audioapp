import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';
import 'rotary_knob.dart';

/// Bitwig-inspired compact sampler panel for the device strip.
class SamplerDeviceStrip extends StatelessWidget {
  const SamplerDeviceStrip({
    super.key,
    required this.trackName,
    required this.device,
    required this.sample,
    required this.onParameterChanged,
    required this.onOpenFullscreen,
  });

  final String trackName;
  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final void Function(String parameterId, double value) onParameterChanged;
  final VoidCallback onOpenFullscreen;

  static const Color _panel = Color(0xFF1C1C24);
  static const Color _accent = Color(0xFFE8A54B);
  static const Color _wave = Color(0xFF6EC9A0);

  static String formatCutoffHz(double normalized) {
    const minHz = 20.0;
    const maxHz = 20000.0;
    final hz = minHz * math.pow(maxHz / minHz, normalized.clamp(0, 1));
    if (hz >= 10000) {
      return '${(hz / 1000).toStringAsFixed(1)} kHz';
    }
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(2)} kHz';
    }
    return '${hz.round()} Hz';
  }

  static String formatQ(double normalized) {
    final q = 0.1 + normalized.clamp(0, 1) * 9.9;
    return q.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sampleName = sample?.name ?? 'No sample loaded';
    final peaks = sample?.waveformPeaks ?? const <double>[];

    return Material(
      color: _panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WaveformHeader(
                    sampleName: sampleName,
                    onOpenFullscreen: onOpenFullscreen,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: onOpenFullscreen,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF121218),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: sample == null
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: peaks.isEmpty
                              ? Center(
                                  child: Text(
                                    'Tap to open sampler',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white38,
                                    ),
                                  ),
                                )
                              : CustomPaint(
                                  painter: WaveformPainter(
                                    peaks: peaks,
                                    color: _wave,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 98,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _AdsrPanel(
                            device: device,
                            onParameterChanged: onParameterChanged,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _FilterPanel(
                            device: device,
                            onParameterChanged: onParameterChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformHeader extends StatelessWidget {
  const _WaveformHeader({
    required this.sampleName,
    required this.onOpenFullscreen,
  });

  final String sampleName;
  final VoidCallback onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onOpenFullscreen,
      child: Row(
        children: [
          Text(
            'SAMPLER',
            style: theme.textTheme.labelSmall?.copyWith(
              color: SamplerDeviceStrip._accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sampleName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Open sampler editor',
            visualDensity: VisualDensity.compact,
            onPressed: onOpenFullscreen,
            icon: const Icon(Icons.open_in_full, size: 18, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _AdsrPanel extends StatelessWidget {
  const _AdsrPanel({
    required this.device,
    required this.onParameterChanged,
  });

  final DeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;

  @override
  Widget build(BuildContext context) {
    return _ParamPanel(
      title: 'ADSR',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          RotaryKnob(
            label: 'A',
            value: device.attack,
            size: 34,
            onChanged: (v) => onParameterChanged('attack', v),
          ),
          RotaryKnob(
            label: 'D',
            value: device.decay,
            size: 34,
            onChanged: (v) => onParameterChanged('decay', v),
          ),
          RotaryKnob(
            label: 'S',
            value: device.sustain,
            size: 34,
            onChanged: (v) => onParameterChanged('sustain', v),
          ),
          RotaryKnob(
            label: 'R',
            value: device.release,
            size: 34,
            onChanged: (v) => onParameterChanged('release', v),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.device,
    required this.onParameterChanged,
  });

  final DeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;

  static const _modes = ['LP', 'HP', 'BP', 'NT'];

  @override
  Widget build(BuildContext context) {
    final modeIndex = device.filterMode.clamp(0, _modes.length - 1);

    return _ParamPanel(
      title: 'FILTER',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_modes.length, (index) {
              final selected = index == modeIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => onParameterChanged('filterMode', index.toDouble()),
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    width: 22,
                    height: 14,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? SamplerDeviceStrip._accent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: selected
                            ? SamplerDeviceStrip._accent.withValues(alpha: 0.7)
                            : Colors.white12,
                      ),
                    ),
                    child: Text(
                      _modes[index],
                      style: TextStyle(
                        color: selected ? SamplerDeviceStrip._accent : Colors.white38,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RotaryKnob(
                label: 'Cutoff',
                value: device.filterCutoff,
                displayValue: SamplerDeviceStrip.formatCutoffHz(device.filterCutoff),
                size: 28,
                onChanged: (v) => onParameterChanged('filterCutoff', v),
              ),
              RotaryKnob(
                label: 'Q',
                value: device.filterQ,
                displayValue: SamplerDeviceStrip.formatQ(device.filterQ),
                size: 28,
                onChanged: (v) => onParameterChanged('filterQ', v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParamPanel extends StatelessWidget {
  const _ParamPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRect(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
              ),
              const SizedBox(height: 2),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
