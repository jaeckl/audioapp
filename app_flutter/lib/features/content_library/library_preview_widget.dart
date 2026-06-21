import 'package:flutter/material.dart';

import '../sample_library/sample_library_screen.dart';

class LibraryPreviewWidget extends StatelessWidget {
  const LibraryPreviewWidget({
    super.key,
    this.peaks,
    this.color = Colors.white,
    this.height = 36,
    this.width = 52,
  });

  /// Normalised 0.0–1.0 amplitude peaks.
  /// `null` = loading/unknown, empty = error, non-empty = waveform.
  final List<double>? peaks;
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

    // Waveform
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CustomPaint(
        size: Size(width, height),
        painter: WaveformPainter(peaks: peaks!, color: color),
      ),
    );
  }
}
