import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';

part 'drum_machine_device_panel_pad_minimap_painter.dart';

class DrumMachineDevicePanel extends StatelessWidget {
  const DrumMachineDevicePanel({
    super.key,
    required this.device,
    required this.selectedNote,
    required this.bankStart,
    required this.chainExpanded,
    required this.onSelectNote,
    required this.onBankChanged,
    required this.onToggleChain,
    required this.onTriggerNote,
    required this.onEmptyPadTap,
  });

  static const double designWidth = 330;
  final DrumMachineDeviceSnapshot device;
  final int selectedNote;
  final int bankStart;
  final bool chainExpanded;
  final ValueChanged<int> onSelectNote;
  final ValueChanged<int> onBankChanged;
  final VoidCallback onToggleChain;
  final ValueChanged<int> onTriggerNote;
  final ValueChanged<int> onEmptyPadTap;

  String _noteName(int note) {
    const names = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    return '${names[note % 12]}${note ~/ 12 - 1}';
  }

  @override
  Widget build(BuildContext context) {
    final safeStart = bankStart.clamp(0, 112);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Row(children: [
        SizedBox(
          width: 34,
          child: LayoutBuilder(builder: (context, constraints) {
            void scrub(Offset position) {
              final row = (position.dy / constraints.maxHeight * 32)
                  .floor()
                  .clamp(0, 31);
              onBankChanged((((31 - row) ~/ 4) * 16).clamp(0, 112));
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (event) => scrub(event.localPosition),
              onVerticalDragUpdate: (event) => scrub(event.localPosition),
              child: CustomPaint(
                painter:
                    _PadMinimapPainter(device: device, bankStart: safeStart),
                size: Size.infinite,
              ),
            );
          }),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            const gridGap = 5.0;
            final rowHeight = (constraints.maxHeight - gridGap * 5) / 4;
            return GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: gridGap),
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: gridGap,
                  mainAxisSpacing: gridGap,
                  mainAxisExtent: rowHeight),
              itemCount: 16,
              itemBuilder: (context, index) {
                final row = index ~/ 4;
                final column = index % 4;
                final note = safeStart + (3 - row) * 4 + column;
                final pad = device.padForNote(note);
                final selected = note == selectedNote;
                final populated = pad.devices.isNotEmpty;
                return Material(
                  color: selected
                      ? const Color(0xFF6D5BD0)
                      : populated
                          ? const Color(0xFF343044)
                          : const Color(0xFF252530),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)),
                  child: InkWell(
                    onLongPress: onToggleChain,
                    onTap: () {
                      onSelectNote(note);
                      if (populated) {
                        onTriggerNote(note);
                      } else {
                        onEmptyPadTap(note);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_noteName(note),
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text(
                                pad.name.isNotEmpty
                                    ? pad.name
                                    : populated
                                        ? pad.devices.first.type
                                        : '+',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: populated
                                        ? FontWeight.w400
                                        : FontWeight.w700,
                                    color: populated
                                        ? Colors.white70
                                        : Colors.white70)),
                          ]),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ]),
    );
  }
}
