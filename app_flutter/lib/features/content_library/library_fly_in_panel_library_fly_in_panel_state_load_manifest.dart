part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateLoadmanifestOperation on LibraryFlyInPanelState {
Future<void> _loadManifest() async {
    try {
      final manifest = await LibraryManifest.load();
      if (mounted) {
        setState(() => _manifest = manifest);
      }
    } catch (_) {
      // manifest unavailable — non-critical
    }
  }
}
