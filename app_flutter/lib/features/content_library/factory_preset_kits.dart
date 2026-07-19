part of 'factory_preset_json.dart';

/// Pad note → voice slug (matches `preset:{family}-{voice}`).
const _voiceNotes = <String, int>{
  'kick': 36,
  'snare': 37,
  'chh': 38,
  'ohh': 39,
  'clap': 40,
  'rim': 40,
  'tomlo': 41,
  'tommid': 42,
  'tomhi': 43,
  'ride': 46,
  'crash': 47,
};

const _voiceNames = <String, String>{
  'kick': 'Kick',
  'snare': 'Snare',
  'chh': 'Closed Hat',
  'ohh': 'Open Hat',
  'clap': 'Clap',
  'rim': 'Rim',
  'tomlo': 'Tom Lo',
  'tommid': 'Tom Mid',
  'tomhi': 'Tom Hi',
  'ride': 'Ride',
  'crash': 'Crash',
};

/// Family slug → voices present in [DevicePresetStore] for that family.
const _familyVoices = <String, List<String>>{
  '808': [
    'kick',
    'snare',
    'clap',
    'chh',
    'ohh',
    'rim',
    'tomlo',
    'tommid',
    'tomhi',
    'crash',
  ],
  '909': [
    'kick',
    'snare',
    'clap',
    'chh',
    'ohh',
    'rim',
    'tomlo',
    'tommid',
    'tomhi',
    'ride',
    'crash',
  ],
  'electro': ['kick', 'snare', 'clap', 'chh', 'ohh', 'rim', 'tommid', 'crash'],
  'trap': ['kick', 'snare', 'clap', 'chh', 'ohh', 'rim', 'tomlo'],
  'boombap': ['kick', 'snare', 'rim', 'chh', 'ohh', 'tomlo', 'tommid'],
  'house': ['kick', 'snare', 'clap', 'chh', 'ohh', 'ride', 'crash'],
  'techno': ['kick', 'snare', 'chh', 'ohh', 'rim', 'ride', 'crash'],
  'pop': ['kick', 'snare', 'clap', 'chh', 'ohh', 'rim', 'tommid', 'crash'],
  'rnb': ['kick', 'snare', 'rim', 'chh', 'ohh', 'clap', 'tomlo'],
  'reggae': ['kick', 'snare', 'rim', 'chh', 'ohh'],
  'rock': [
    'kick',
    'snare',
    'rim',
    'chh',
    'ohh',
    'tomlo',
    'tommid',
    'tomhi',
    'ride',
    'crash',
  ],
  'breakbeat': ['kick', 'snare', 'rim', 'chh', 'ohh', 'tomlo', 'tomhi', 'crash'],
  'disco': ['kick', 'snare', 'clap', 'chh', 'ohh', 'ride'],
  'dnb': ['kick', 'snare', 'chh', 'ohh', 'rim', 'crash'],
  'ambient': ['kick', 'snare', 'chh', 'ohh', 'rim'],
};

const _familyTitles = <String, String>{
  '808': '808',
  '909': '909',
  'electro': 'Electro',
  'trap': 'Trap',
  'boombap': 'Boom Bap',
  'house': 'House',
  'techno': 'Techno',
  'pop': 'Pop',
  'rnb': 'R&B',
  'reggae': 'Reggae',
  'rock': 'Rock',
  'breakbeat': 'Breakbeat',
  'disco': 'Disco',
  'dnb': 'DnB',
  'ambient': 'Ambient',
};

Map<String, dynamic> _kitDocument(String family) {
  final voices = _familyVoices[family]!;
  final padsByNote = <int, Map<String, dynamic>>{};

  for (final voice in voices) {
    final note = _voiceNotes[voice]!;
    final pad = padsByNote.putIfAbsent(
      note,
      () => {
        'note': note,
        'name': _voiceNames[voice]!,
        'gain': 1.0,
        'pan': 0.5,
        'muted': false,
        'solo': false,
        'chokeGroup': (voice == 'chh' || voice == 'ohh') ? 1 : 0,
        'devices': <dynamic>[],
      },
    );
    // Prefer clap name when both clap+rim land on note 40.
    if (voice == 'clap') {
      pad['name'] = 'Clap';
    } else if (voice == 'rim' && pad['name'] == 'Rim') {
      pad['name'] = 'Rim';
    }
    if (voice == 'chh' || voice == 'ohh') {
      pad['chokeGroup'] = 1;
    }
    (pad['devices'] as List).add({'presetRef': 'preset:$family-$voice'});
  }

  final pads = padsByNote.values.toList()
    ..sort((a, b) => (a['note'] as int).compareTo(b['note'] as int));

  return {
    'presetVersion': FactoryPresetJson.presetVersion,
    'device': {
      'id': 'factory',
      'type': 'drum_machine',
      'bypass': false,
      'pads': pads,
    },
    'automationClips': <dynamic>[],
    'modEdges': <dynamic>[],
    'modulators': <dynamic>[],
  };
}

final Map<String, Map<String, dynamic>> _kitDocuments = {
  for (final family in _familyVoices.keys)
    'preset:kit-$family': _kitDocument(family),
};

/// Manifest metadata for the 15 drum_machine kit presets.
List<Map<String, dynamic>> factoryKitManifestEntries() {
  const genreTags = <String, List<String>>{
    '808': ['edm', 'electro'],
    '909': ['house', 'techno'],
    'electro': ['electro'],
    'trap': ['trap'],
    'boombap': ['hiphop', 'lofi'],
    'house': ['house'],
    'techno': ['techno', 'dark'],
    'pop': ['pop', 'clean'],
    'rnb': ['rnb'],
    'reggae': ['reggae'],
    'rock': ['rock'],
    'breakbeat': ['breakbeat'],
    'disco': ['disco', 'funk'],
    'dnb': ['dnb'],
    'ambient': ['ambient'],
  };

  return [
    for (final family in _familyVoices.keys)
      {
        'id': 'preset:kit-$family',
        'title': '${_familyTitles[family]} · Kit',
        'subtitle': '${_familyTitles[family]} drum machine · family voices',
        'deviceType': 'drum_machine',
        'tags': [
          'factory',
          'drums',
          family,
          ...?genreTags[family],
        ],
      },
  ];
}
