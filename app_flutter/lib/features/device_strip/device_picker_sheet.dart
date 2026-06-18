import 'package:flutter/material.dart';

/// Bottom sheet to pick a device type when inserting into the chain.
Future<String?> showDevicePickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A1A22),
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
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
              subtitle: const Text('2 osc · multimode · 8-voice poly'),
              onTap: () => Navigator.pop(context, 'subtractive_synth'),
            ),
            ListTile(
              leading: const Icon(Icons.album, color: Color(0xFFE85D4B)),
              title: const Text('Kick Generator'),
              subtitle: const Text('808-style · pitch-drop body'),
              onTap: () => Navigator.pop(context, 'kick_generator'),
            ),
            ListTile(
              leading: const Icon(Icons.album_outlined, color: Color(0xFFF0C14B)),
              title: const Text('Snare Generator'),
              subtitle: const Text('Body + noise · tunable'),
              onTap: () => Navigator.pop(context, 'snare_generator'),
            ),
            ListTile(
              leading: const Icon(Icons.back_hand, color: Color(0xFFE8A0C8)),
              title: const Text('Clap Generator'),
              subtitle: const Text('Multi-hit noise · room clap'),
              onTap: () => Navigator.pop(context, 'clap_generator'),
            ),
            ListTile(
              leading: const Icon(Icons.blur_on, color: Color(0xFF9AD4E8)),
              title: const Text('Cymbal Generator'),
              subtitle: const Text('Metallic noise · hat or crash'),
              onTap: () => Navigator.pop(context, 'cymbal_generator'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Effects',
                style: TextStyle(
                  color: Color(0xFF9A9AA8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.door_sliding, color: Color(0xFF6EC9A8)),
              title: const Text('Gate'),
              subtitle: const Text('Noise gate · threshold & hold'),
              onTap: () => Navigator.pop(context, 'gate'),
            ),
            ListTile(
              leading: const Icon(Icons.compress, color: Color(0xFFE8A54B)),
              title: const Text('Compressor'),
              subtitle: const Text('Downward · ratio & makeup'),
              onTap: () => Navigator.pop(context, 'compressor'),
            ),
            ListTile(
              leading: const Icon(Icons.unfold_more, color: Color(0xFF9AD4E8)),
              title: const Text('Expander'),
              subtitle: const Text('Downward · below threshold'),
              onTap: () => Navigator.pop(context, 'expander'),
            ),
            ListTile(
              leading: const Icon(Icons.horizontal_rule, color: Color(0xFFE85D4B)),
              title: const Text('Limiter'),
              subtitle: const Text('Brick-wall ceiling · track bus'),
              onTap: () => Navigator.pop(context, 'limiter'),
            ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      );
    },
  );
}
