import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'library_catalog.dart';
import 'library_category.dart';
import 'library_category_menu.dart';
import 'library_content_pane.dart';
import 'library_header.dart';
import 'library_manifest.dart';
import 'library_preset_preview_bar.dart';
import 'library_theme.dart';

/// Slide-in content library: half width in landscape, full width in portrait.
class LibraryFlyInPanel extends StatefulWidget {
  const LibraryFlyInPanel({
    super.key,
    required this.snapshot,
    required this.onClose,
    required this.onPreviewAudio,
    required this.onInsertAudio,
    required this.onImportAudio,
    this.initialCategory = LibraryCategory.audioClips,
    this.onMidiClipTap,
    this.onMidiPreviewTap,
    this.onAutomationTap,
    this.onAutomationPreviewTap,
    this.onPresetTap,
    this.onPresetPreviewTap,
    this.onStopPreview,
  });

  final ProjectSnapshot snapshot;
  final VoidCallback onClose;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final VoidCallback onImportAudio;
  final LibraryCategory initialCategory;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryMidiItem item)? onMidiPreviewTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryAutomationItem item)? onAutomationPreviewTap;
  final void Function(LibraryPresetItem item)? onPresetTap;
  final void Function(LibraryPresetItem item, {double startBeat, bool loop})? onPresetPreviewTap;
  /// Optional: invoked when the panel wants to halt any active engine preview
  /// (e.g. when the user toggles auto-play/loop off mid-preview).
  final VoidCallback? onStopPreview;

  @override
  State<LibraryFlyInPanel> createState() => LibraryFlyInPanelState();
}

class LibraryFlyInPanelState extends State<LibraryFlyInPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late LibraryCategory _category;
  LibraryManifest? _manifest;
  String? _selectedItemId;
  bool _presetPreviewLoopEnabled = true;
  double _presetScrubBeat = 0.0;

  /// Preview timing state. When [_previewActive] is true the timer tick
  /// advances [_presetScrubBeat] at the configured BPM so the playhead
  /// visually moves while the engine plays.
  bool _previewActive = false;
  bool _previewLoop = true;
  double _previewLengthBeats = 0.0;
  double _previewStartBeat = 0.0;
  int _previewBpm = 120;
  DateTime? _previewStartedAt;
  Timer? _previewTicker;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _loadManifest();
  }

  @override
  void dispose() {
    _controller.dispose();
    _previewTicker?.cancel();
    super.dispose();
  }

  /// Starts (or restarts) the visual playhead timer so the bar's playhead
  /// line tracks the engine's preview playhead. The math mirrors the engine:
  /// beat = startBeat + elapsed_seconds * (bpm / 60).
  void _startPreviewAnimation({
    required double startBeat,
    required double lengthBeats,
    required int bpm,
    required bool loop,
  }) {
    _previewTicker?.cancel();
    _previewActive = true;
    _previewLoop = loop;
    _previewLengthBeats = lengthBeats;
    _previewStartBeat = startBeat;
    _previewBpm = bpm <= 0 ? 120 : bpm;
    _previewStartedAt = DateTime.now();
    _presetScrubBeat = startBeat;

    _previewTicker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted || !_previewActive || _previewStartedAt == null) return;
      final elapsedMs = DateTime.now().difference(_previewStartedAt!).inMicroseconds / 1000.0;
      final elapsedBeats = (elapsedMs / 1000.0) * (_previewBpm / 60.0);
      double beat = _previewStartBeat + elapsedBeats;
      if (_previewLoop && _previewLengthBeats > 0) {
        beat = beat % _previewLengthBeats;
      } else if (beat >= _previewLengthBeats) {
        beat = _previewLengthBeats;
        _previewActive = false;
      }
      if (beat != _presetScrubBeat) {
        setState(() => _presetScrubBeat = beat);
      }
    });
  }

  void _stopPreviewAnimation() {
    _previewTicker?.cancel();
    _previewTicker = null;
    _previewActive = false;
  }

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

  Future<void> close() async {
    _stopPreviewAnimation();
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  void openCategory(LibraryCategory category) {
    setState(() {
      _category = category;
      _selectedItemId = null;
      _presetPreviewLoopEnabled = true;
      _presetScrubBeat = 0;
      _stopPreviewAnimation();
    });
  }

/// Wraps the parent's preset preview callback to:
///  - inject the current preview-bar scrub beat as the default startBeat
///  - inject the current auto-play/loop state as the default `loop`
///  - keep the panel's stored scrub beat in sync with what the user is playing
///  - animate the visual playhead while the engine is playing
void _onPresetPreviewTap(LibraryPresetItem item,
    {double? startBeat, bool? loop}) {
  final effectiveStart = startBeat ?? _presetScrubBeat;
  final effectiveLoop = loop ?? _presetPreviewLoopEnabled;
  if (startBeat != null) {
    _presetScrubBeat = startBeat;
  }

  // Start the visual playhead animation so the bar shows the head moving.
  // Use the project's BPM and a 4-bar default length (matches the C-arpeggio
  // fallback used in daw_shell._onLibraryPresetPreviewTap).
  final bpm = widget.snapshot.bpm;
  final lengthBeats = _computePreviewLengthBeats();
  setState(() {
    _startPreviewAnimation(
      startBeat: effectiveStart,
      lengthBeats: lengthBeats,
      bpm: bpm,
      loop: effectiveLoop,
    );
  });

  widget.onPresetPreviewTap?.call(item,
      startBeat: effectiveStart, loop: effectiveLoop);
}

double _computePreviewLengthBeats() {
  // Mirror the logic in daw_shell._onLibraryPresetPreviewTap: longest MIDI
  // clip on the selected track, with a 4-beat minimum so an empty track
  // still animates something visible.
  const minBeats = 4.0;
  final trackId = widget.snapshot.selectedTrackId;
  if (trackId == null) return minBeats;
  for (final t in widget.snapshot.tracks) {
    if (t.id != trackId) continue;
    double max = 0;
    for (final clip in t.midiClips) {
      final end = clip.startBeat + clip.lengthBeats;
      if (end > max) max = end;
    }
    return max > minBeats ? max : minBeats;
  }
  return minBeats;
}

void _onItemSelected(String? itemId) {
    setState(() {
      _selectedItemId = itemId;
    });
  }

  void _onInsert() {
    if (_selectedItemId == null) return;
    final items = LibraryCatalog.itemsFor(
      _category,
      widget.snapshot,
      manifest: _manifest,
    );
    LibraryItem item;
    try {
      item = items.firstWhere((i) => i.id == _selectedItemId);
    } catch (_) {
      return;
    }
    switch (item) {
      case final LibraryAudioItem audio when !audio.isProjectClip:
        widget.onInsertAudio(audio.sample);
      case final LibraryMidiItem midi:
        widget.onMidiClipTap?.call(midi);
      case final LibraryAutomationItem automation:
        widget.onAutomationTap?.call(automation);
      case final LibraryPresetItem preset:
        widget.onPresetTap?.call(preset);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final panelWidth = landscape ? size.width * 0.5 : size.width;
    final accent = LibraryTheme.accentFor(_category);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: close,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: landscape ? Colors.black.withValues(alpha: 0.18) : Colors.black54,
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: panelWidth,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: LibraryTheme.panelBackground,
              elevation: 12,
              child: SafeArea(
                right: false,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: LibraryTheme.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LibraryHeader(
                        onClose: close,
                        selectedItemId: _selectedItemId,
                        onInsert: _selectedItemId != null ? _onInsert : null,
                        accent: accent,
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LibraryCategoryMenu(
                              selected: _category,
                              onSelected: (category) => setState(() {
                                _category = category;
                                _selectedItemId = null;
                                _presetPreviewLoopEnabled = true;
                                _presetScrubBeat = 0;
                                _stopPreviewAnimation();
                              }),
                            ),
                            Expanded(
                              child: LibraryContentPane(
                                category: _category,
                                snapshot: widget.snapshot,
                                onPreviewAudio: widget.onPreviewAudio,
                                onInsertAudio: widget.onInsertAudio,
                                onImportAudio: widget.onImportAudio,
                                onItemSelected: _onItemSelected,
                                onMidiClipTap: widget.onMidiClipTap,
                                onMidiPreviewTap: widget.onMidiPreviewTap,
                                onAutomationTap: widget.onAutomationTap,
                                onAutomationPreviewTap: widget.onAutomationPreviewTap,
                                onPresetTap: widget.onPresetTap,
                                onPresetPreviewTap: _onPresetPreviewTap,
                                autoPlayOnSelect: _presetPreviewLoopEnabled,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_category == LibraryCategory.devicePresets &&
                          _selectedItemId != null)
                        PresetPreviewBar(
                          snapshot: widget.snapshot,
                          selectedTrackId: widget.snapshot.selectedTrackId,
                          loopEnabled: _presetPreviewLoopEnabled,
                          onLoopToggled: (enabled) {
                            setState(() {
                              _presetPreviewLoopEnabled = enabled;
                              // Toggling the loop flag stops any currently
                              // playing preview — both visually (the ticker)
                              // and in the engine. The user is signaling
                              // "stop autoplay; I'll press play manually
                              // from now on", so the active preview should
                              // also pause.
                              if (!enabled) {
                                _stopPreviewAnimation();
                                widget.onStopPreview?.call();
                              }
                            });
                          },
                          playheadBeats: _presetScrubBeat,
                          onScrub: (beat) {
                            // Tap-to-seek already updated _presetScrubBeat inside the
                            // bar; here we just kick off a fresh preview at that beat
                            // so the user hears audio immediately.
                            final items = LibraryCatalog.itemsFor(
                              _category,
                              widget.snapshot,
                              manifest: _manifest,
                            );
                            try {
                              final item = items.firstWhere((i) => i.id == _selectedItemId);
                              if (item is LibraryPresetItem) {
                                _onPresetPreviewTap(item, startBeat: beat);
                              }
                            } catch (_) {}
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
