import 'package:flutter/material.dart';

/// Tap-tempo helper — averages last intervals between taps.
class TapTempo {
  TapTempo({this.maxSamples = 4, this.minBpm = 40, this.maxBpm = 300});

  final int maxSamples;
  final int minBpm;
  final int maxBpm;

  final List<DateTime> _taps = [];

  int? registerTap() {
    final now = DateTime.now();
    _taps.add(now);
    if (_taps.length > maxSamples) {
      _taps.removeAt(0);
    }
    if (_taps.length < 2) {
      return null;
    }

    var totalMs = 0;
    for (var i = 1; i < _taps.length; i++) {
      totalMs += _taps[i].difference(_taps[i - 1]).inMilliseconds;
    }
    final avgSec = totalMs / (_taps.length - 1) / 1000.0;
    if (avgSec <= 0) {
      return null;
    }
    final bpm = (60.0 / avgSec).round();
    return bpm.clamp(minBpm, maxBpm);
  }

  void reset() => _taps.clear();
}

/// Overflow actions for transport (tap tempo, loop toggle, export).
class TransportOverflowSheet extends StatefulWidget {
  const TransportOverflowSheet({
    super.key,
    required this.bpm,
    required this.loopEnabled,
    required this.onBpmChanged,
    required this.onLoopToggled,
    this.onExportMix,
  });

  final int bpm;
  final bool loopEnabled;
  final ValueChanged<int> onBpmChanged;
  final ValueChanged<bool> onLoopToggled;
  final VoidCallback? onExportMix;

  @override
  State<TransportOverflowSheet> createState() => _TransportOverflowSheetState();
}

class _TransportOverflowSheetState extends State<TransportOverflowSheet> {
  final _tapTempo = TapTempo();
  String? _tapHint;
  late bool _loopEnabled;

  @override
  void initState() {
    super.initState();
    _loopEnabled = widget.loopEnabled;
  }

  @override
  void didUpdateWidget(covariant TransportOverflowSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loopEnabled != widget.loopEnabled) {
      _loopEnabled = widget.loopEnabled;
    }
  }

  void _onTapTempo() {
    final bpm = _tapTempo.registerTap();
    if (bpm != null) {
      widget.onBpmChanged(bpm);
      setState(() => _tapHint = 'Set to $bpm BPM');
    } else {
      setState(() => _tapHint = 'Tap again…');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Transport', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.touch_app_outlined),
                title: const Text('Tap tempo'),
                subtitle: Text(_tapHint ?? 'Tap at least twice'),
                onTap: _onTapTempo,
              ),
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Loop playback'),
                subtitle: const Text('Drag the blue markers in the arrangement to set the region'),
                value: _loopEnabled,
                onChanged: (enabled) {
                  setState(() => _loopEnabled = enabled);
                  widget.onLoopToggled(enabled);
                },
              ),
              if (widget.onExportMix != null) ...[
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Export mix (WAV)'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onExportMix!();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
