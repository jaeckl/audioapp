import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TrackSnapshot trackWith(List<Map<String, dynamic>> devices) =>
      TrackSnapshot.fromMap({
        'id': 't1',
        'name': 'Track',
        'devices': devices,
      });

  test('mono clap exposes GM hint pitch regardless of key track', () {
    final track = trackWith([
      {
        'id': 'clap1',
        'type': 'clap_generator',
        'parameters': {'clapKeyTrack': 0.0},
      },
    ]);
    expect(track.drumAnchorPitch, 39);

    final keyed = trackWith([
      {
        'id': 'clap2',
        'type': 'clap_generator',
        'parameters': {'clapKeyTrack': 1.0},
      },
    ]);
    expect(keyed.drumAnchorPitch, 39);
  });

  test('drum_machine suppresses mono-drum anchor hint', () {
    final track = trackWith([
      {
        'id': 'dm1',
        'type': 'drum_machine',
        'pads': [
          {
            'note': 36,
            'name': 'Kick',
            'devices': [
              {'id': 'k1', 'type': 'kick_generator', 'parameters': {}},
            ],
          },
        ],
      },
      {
        'id': 'clap1',
        'type': 'clap_generator',
        'parameters': {},
      },
    ]);
    expect(track.drumAnchorPitch, isNull);
  });
}
