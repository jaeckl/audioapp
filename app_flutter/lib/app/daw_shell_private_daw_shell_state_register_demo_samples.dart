part of 'daw_shell.dart';

extension DawShellStateRegisterdemosamplesOperation on _DawShellState {
Future<ProjectSnapshot> _registerDemoSamples(ProjectSnapshot snapshot) async {
    try {
      var current = snapshot;
      for (final (id, name, file) in _demoSamples) {
        final data = await rootBundle.load('assets/demo_samples/$file');
        current = await widget.bridge.registerDemoSample(
          id: id,
          name: name,
          bytes:
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
      return current;
    } on MissingPluginException {
      return snapshot;
    } catch (_) {
      return snapshot;
    }
  }
}
