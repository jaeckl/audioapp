import 'package:flutter/material.dart';

/// Bottom sheet to pick a device type when inserting into the chain.
Future<String?> showDevicePickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A1A22),
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Insert device',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.piano, color: Color(0xFFE8A54B)),
              title: const Text('Sampler'),
              subtitle: const Text('Play audio samples from MIDI'),
              onTap: () => Navigator.pop(context, 'simple_sampler'),
            ),
            ListTile(
              leading: const Icon(Icons.waves, color: Color(0xFF6EC9E8)),
              title: const Text('Oscillator'),
              subtitle: const Text('Simple sine tone generator'),
              onTap: () => Navigator.pop(context, 'simple_oscillator'),
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq, color: Color(0xFF7B6CF6)),
              title: const Text('Subtractive Synth'),
              subtitle: const Text('2 osc · LP12 · 8-voice poly'),
              onTap: () => Navigator.pop(context, 'subtractive_synth'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
