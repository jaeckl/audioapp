part of 'daw_shell.dart';

extension DawShellStateConfirmremovedeviceOperation on _DawShellState {
Future<ProjectSnapshot?> _confirmRemoveDevice(
    TrackSnapshot track,
    DeviceSnapshot device,
  ) async {
    final label = DeviceStripTheme.labelForDeviceType(device.type);
    final isLastInstrument =
        device.isInstrumentDevice && track.visibleInstrumentCount <= 1;
    final hasAutomation = track.hasLinkedAutomationFor(device.id);

    final message = StringBuffer('Remove $label from this track?');
    if (hasAutomation) {
      message.write('\n\nAutomation linked to this device will be unlinked.');
    }
    if (isLastInstrument) {
      message.write(
        '\n\nThis is the only instrument on the track. MIDI clips will be silent until you add a new device.',
      );
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete device?'),
        content: Text(message.toString()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return null;

    try {
      final snapshot =
          await widget.bridge.removeDeviceFromTrack(deviceId: device.id);
      await _refreshSnapshot(snapshot);
      return snapshot;
    } catch (e) {
      if (!mounted) return null;
      setState(() => _projectError = e.toString());
      return null;
    }
  }
}
