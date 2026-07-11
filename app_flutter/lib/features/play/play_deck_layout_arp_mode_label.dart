part of 'play_deck_layout.dart';

extension ArpModeLabel on ArpMode {
  String get label => switch (this) {
        ArpMode.off => 'Off',
        ArpMode.up => 'Up',
        ArpMode.down => 'Down',
        ArpMode.upDown => 'Up–Down',
        ArpMode.downUp => 'Down–Up',
        ArpMode.random => 'Random',
        ArpMode.chord => 'Chord',
        ArpMode.strum => 'Strum',
      };
}
