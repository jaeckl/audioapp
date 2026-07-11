import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';

part 'library_preview_widget_midi_preview_painter.dart';

class LibraryPreviewWidget extends StatelessWidget {
  const LibraryPreviewWidget({
    super.key,
    this.peaks,
    this.notes,
    this.lengthBeats,
    this.color = Colors.white,
    this.height = 36,
    this.width = 52,
  });

  /// Normalised 0.0–1.0 amplitude peaks for audio.
  /// `null` = loading/unknown, empty = error, non-empty = waveform.
  final List<double>? peaks;

  /// MIDI notes for rendering a mini piano roll.
  final List<MidiNoteSnapshot>? notes;

  /// Total duration in beats of the MIDI clip.
  final double? lengthBeats;

  final Color color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // If notes is provided, render mini piano roll
    if (notes != null && lengthBeats != null) {
      if (notes!.isEmpty || lengthBeats! <= 0) {
        return _buildErrorPlaceholder();
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          color: color.withValues(alpha: 0.05),
          child: CustomPaint(
            size: Size(width, height),
            painter: MidiPreviewPainter(
              notes: notes!,
              lengthBeats: lengthBeats!,
              color: color,
            ),
          ),
        ),
      );
    }

    // Loading shimmer
    if (peaks == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Empty / error placeholder
    if (peaks!.isEmpty) {
      return _buildErrorPlaceholder();
    }

    // Waveform
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CustomPaint(
        size: Size(width, height),
        painter: WaveformPainter(peaks: peaks!, color: color),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.auto_awesome_mosaic_outlined,
        size: 16,
        color: color.withValues(alpha: 0.4),
      ),
    );
  }
}
