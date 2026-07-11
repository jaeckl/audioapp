part of 'transport_overflow_sheet.dart';

class _TransportOverflowSheetState extends State<TransportOverflowSheet> {
  final _tapTempo = TapTempo();
  String? _tapHint;
  late bool _loopEnabled;
  late bool _followEnabled;

  @override
  void initState() {
    super.initState();
    _loopEnabled = widget.loopEnabled;
    _followEnabled = widget.followPlayheadEnabled;
  }

  @override
  void didUpdateWidget(covariant TransportOverflowSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loopEnabled != widget.loopEnabled) {
      _loopEnabled = widget.loopEnabled;
    }
    if (oldWidget.followPlayheadEnabled != widget.followPlayheadEnabled) {
      _followEnabled = widget.followPlayheadEnabled;
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
                subtitle: const Text(
                    'Drag the blue markers in the arrangement to set the region'),
                value: _loopEnabled,
                onChanged: (enabled) {
                  setState(() => _loopEnabled = enabled);
                  widget.onLoopToggled(enabled);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Follow playhead'),
                subtitle: Text(
                  widget.followPlayheadSuspended && _followEnabled
                      ? 'Paused — scroll the timeline or toggle to resume'
                      : 'Scroll the arrangement while playing',
                ),
                value: _followEnabled,
                onChanged: (enabled) {
                  setState(() => _followEnabled = enabled);
                  widget.onFollowPlayheadToggled(enabled);
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
