part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateSyncpreviewtransportspanOperation on _SampleEditorScreenState {
void _syncPreviewTransportSpan() {
    transport.maxClipBeat = _playbackContentLengthBeats;
    if (transport.clipLocalBeat > transport.maxClipBeat) {
      transport.seekClipLocal(transport.maxClipBeat);
    }
  }
}
