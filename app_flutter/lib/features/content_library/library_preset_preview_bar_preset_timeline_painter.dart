part of 'library_preset_preview_bar.dart';

class _PresetTimelinePainter extends CustomPainter {
  _PresetTimelinePainter({
    required this.clips,
    required this.windowStart,
    required this.windowEnd,
    required this.playheadBeat,
    required this.accent,
  });

  final List<PresetPreviewClipSpan> clips;
  final double windowStart;
  final double windowEnd;
  final double playheadBeat;
  final Color accent;

  static const _midiClipFill = Color(0xFF1E2430);
  static const _sampleClipFill = Color(0xFF1A2820);
  static const _autoClipFill = Color(0xFF241E2C);
  static const _noteFill = Color(0xD0A8D4E8);

  @override
  void paint(Canvas canvas, Size size) {
    final span = windowEnd - windowStart;
    if (span <= 0 || size.width <= 0) return;
    final pxPerBeat = size.width / span;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(7),
      ),
      Paint()..color = LibraryTheme.cardBackground,
    );

    _paintGrid(canvas, size, pxPerBeat);

    for (final clip in clips) {
      _paintClip(canvas, size, clip, pxPerBeat);
    }

    if (clips.isEmpty) {
      _paintEmptyHint(canvas, size);
    }

    _paintPlayhead(canvas, size, pxPerBeat);
  }

  void _paintGrid(Canvas canvas, Size size, double pxPerBeat) {
    final startBar = windowStart.floor();
    final endBar = windowEnd.ceil();
    final minor = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = const Color(0x18FFFFFF)
      ..strokeWidth = 1;

    for (var b = startBar; b <= endBar; b++) {
      final x = (b - windowStart) * pxPerBeat;
      if (x < 0 || x > size.width) continue;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        b % 4 == 0 ? major : minor,
      );
    }
  }

  void _paintClip(
    Canvas canvas,
    Size size,
    PresetPreviewClipSpan clip,
    double pxPerBeat,
  ) {
    final left = (clip.startBeat - windowStart) * pxPerBeat;
    final right =
        (clip.startBeat + clip.lengthBeats - windowStart) * pxPerBeat;
    if (right < 0 || left > size.width) return;

    final rect = Rect.fromLTRB(
      left.clamp(0, size.width),
      4,
      right.clamp(0, size.width),
      size.height - 4,
    );
    if (rect.width < 1) return;

    final fill = switch (clip.kind) {
      ClipContentKind.midi => _midiClipFill,
      ClipContentKind.sample => _sampleClipFill,
      ClipContentKind.automation => _autoClipFill,
    };
    final border = switch (clip.kind) {
      ClipContentKind.midi => LibraryTheme.accentMidi.withValues(alpha: 0.45),
      ClipContentKind.sample => LibraryTheme.accentAudio.withValues(alpha: 0.4),
      ClipContentKind.automation =>
        LibraryTheme.accentAutomation.withValues(alpha: 0.45),
    };

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    if (clip.kind == ClipContentKind.midi) {
      _paintMidiNotes(canvas, rect, clip, pxPerBeat);
    } else {
      _paintLabel(canvas, rect, clip.name);
    }
  }

  void _paintMidiNotes(
    Canvas canvas,
    Rect clipRect,
    PresetPreviewClipSpan clip,
    double pxPerBeat,
  ) {
    if (clip.notes.isEmpty || clip.lengthBeats <= 0) {
      _paintLabel(canvas, clipRect, 'MIDI');
      return;
    }

    var minPitch = clip.notes.first.pitch;
    var maxPitch = clip.notes.first.pitch;
    for (final n in clip.notes) {
      minPitch = math.min(minPitch, n.pitch);
      maxPitch = math.max(maxPitch, n.pitch);
    }
    final pitchSpan = math.max(12, maxPitch - minPitch + 1);
    final center = (minPitch + maxPitch) ~/ 2;
    final viewMin = center - (pitchSpan ~/ 2);
    final viewMax = viewMin + pitchSpan - 1;
    final rowH = clipRect.height / pitchSpan;
    final contentLen =
        clip.contentLengthBeats > 0 ? clip.contentLengthBeats : clip.lengthBeats;
    final looping = clip.loopContent &&
        contentLen > 0 &&
        clip.lengthBeats > contentLen + 1e-6;

    final fill = Paint()..color = _noteFill;
    final repeatFill =
        Paint()..color = _noteFill.withValues(alpha: 0.45);

    void paintTile(double tileOrigin, {required bool repeat}) {
      final paint = repeat ? repeatFill : fill;
      for (final note in clip.notes) {
        final localStart = tileOrigin + note.startBeat;
        if (localStart >= clip.lengthBeats) continue;
        final x = clipRect.left + localStart * pxPerBeat;
        final w = math.max(1.0, note.durationBeats * pxPerBeat);
        final y = clipRect.top + (viewMax - note.pitch) * rowH;
        final h = math.max(1.0, rowH - 0.4);
        final noteRect = Rect.fromLTWH(x, y, w, h).intersect(clipRect);
        if (noteRect.width <= 0 || noteRect.height <= 0) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(noteRect, const Radius.circular(1)),
          paint,
        );
      }
    }

    if (looping) {
      for (var origin = 0.0; origin < clip.lengthBeats; origin += contentLen) {
        paintTile(origin, repeat: origin > 0);
      }
    } else {
      paintTile(0, repeat: false);
    }
  }

  void _paintLabel(Canvas canvas, Rect rect, String text) {
    if (rect.width < 28) return;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: LibraryTheme.labelMuted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 8);
    tp.paint(
      canvas,
      Offset(rect.left + 4, rect.center.dy - tp.height / 2),
    );
  }

  void _paintEmptyHint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'No MIDI on selected track — demo phrase',
        style: TextStyle(
          color: LibraryTheme.labelMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 16);
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }

  void _paintPlayhead(Canvas canvas, Size size, double pxPerBeat) {
    final x = (playheadBeat - windowStart) * pxPerBeat;
    if (x < -8 || x > size.width + 8) return;

    final line = Paint()
      ..color = accent
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(x, 6), Offset(x, size.height), line);

    final handle = Path()
      ..moveTo(x, 0)
      ..lineTo(x + 6, 7)
      ..lineTo(x - 6, 7)
      ..close();
    canvas.drawPath(handle, Paint()..color = accent);
    canvas.drawPath(
      handle,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_PresetTimelinePainter old) =>
      clips != old.clips ||
      windowStart != old.windowStart ||
      windowEnd != old.windowEnd ||
      playheadBeat != old.playheadBeat ||
      accent != old.accent;
}
