part of 'sample_editor_screen.dart';

class _SlicePanelState extends State<_SlicePanel> {
  _SliceTab _tab = _SliceTab.auto;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ToolCardHeader(
            title: 'SLICING',
            hint: 'TAP TO ADD  •  TAP MARKER TO SELECT  •  DRAG TO MOVE',
          ),
          const SizedBox(height: 6),
          _SliceTabBar(
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildBody()),
        ],
      );

  Widget _buildBody() => switch (_tab) {
        _SliceTab.auto => _autoBody(),
        _SliceTab.edit => _editBody(),
        _SliceTab.map => _mapBody(),
      };

  Widget _autoBody() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _SliceChoiceChip(
                label: 'Transient',
                active: widget.autoMode == _SliceAutoMode.transient,
                onTap: () =>
                    widget.onAutoModeChanged(_SliceAutoMode.transient)),
            const SizedBox(width: 5),
            _SliceChoiceChip(
                label: 'Even',
                active: widget.autoMode == _SliceAutoMode.even,
                onTap: () => widget.onAutoModeChanged(_SliceAutoMode.even)),
            const SizedBox(width: 5),
            _SliceChoiceChip(
                label: 'Grid',
                active: widget.autoMode == _SliceAutoMode.grid,
                onTap: () => widget.onAutoModeChanged(_SliceAutoMode.grid)),
          ]),
          const SizedBox(height: 10),
          Expanded(child: _autoControl()),
          Row(children: [
            Expanded(
              child: _SliceCommandButton(
                label: 'Auto Slice',
                icon: Icons.auto_fix_high,
                primary: true,
                onTap: widget.onAutoSlice,
              ),
            ),
            const SizedBox(width: 6),
            _SliceChoiceChip(
              label: widget.replaceExisting ? 'Replace' : 'Add',
              active: widget.replaceExisting,
              onTap: () =>
                  widget.onReplaceExistingChanged(!widget.replaceExisting),
            ),
          ]),
          if (widget.status != null) ...[
            const SizedBox(height: 7),
            Text(widget.status!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:
                        AutomationEditorTheme.labelMuted.withValues(alpha: .95),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      );

  Widget _autoControl() => switch (widget.autoMode) {
        _SliceAutoMode.transient => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SliceSliderRow(
                label: 'Sensitivity',
                valueLabel: '${(widget.sensitivity * 100).round()}%',
                value: widget.sensitivity,
                onChanged: widget.onSensitivityChanged,
              ),
              _SliceSliderRow(
                label: 'Min gap',
                valueLabel: '${(widget.minGap * 100).round()}%',
                value: widget.minGap,
                onChanged: (value) =>
                    widget.onMinGapChanged(value.clamp(.01, .20)),
              ),
            ],
          ),
        _SliceAutoMode.even => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SliceSliderRow(
                label: 'Divisions',
                valueLabel: '${widget.evenDivisions}',
                value: (widget.evenDivisions - 2) / 30,
                onChanged: (value) =>
                    widget.onEvenDivisionsChanged((2 + value * 30).round()),
              ),
            ],
          ),
        _SliceAutoMode.grid => Center(
            child: Row(children: [
              const Text('Grid division',
                  style: TextStyle(
                      color: AutomationEditorTheme.labelMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              DropdownButton<SampleEditSnap>(
                value: widget.gridDivision,
                underline: const SizedBox.shrink(),
                dropdownColor: AutomationEditorTheme.panelBackground,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                items: SampleEditSnap.values
                    .where((value) => value != SampleEditSnap.off)
                    .map((value) => DropdownMenuItem(
                        value: value, child: Text(value.shortLabel)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) widget.onGridDivisionChanged(value);
                },
              ),
            ]),
          ),
      };

  Widget _editBody() {
    final selected = widget.selectedMarkerPosition;
    final enabled = selected != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          enabled
              ? 'Selected marker ${(selected * 100).round()}%'
              : 'Select a marker on the waveform to edit it.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Row(children: [
          Expanded(
            child: _SliceCommandButton(
              label: 'Audition',
              icon: Icons.play_arrow,
              onTap: enabled ? widget.onAuditionSelected : null,
            ),
          ),
          const SizedBox(width: 6),
          _SliceIconButton(
              icon: Icons.chevron_left,
              tooltip: 'Nudge left',
              onTap: enabled ? () => widget.onNudgeSelected(-1) : null),
          const SizedBox(width: 5),
          _SliceIconButton(
              icon: Icons.chevron_right,
              tooltip: 'Nudge right',
              onTap: enabled ? () => widget.onNudgeSelected(1) : null),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: _SliceCommandButton(
              label: 'Delete Marker',
              icon: Icons.delete_outline,
              onTap: enabled ? widget.onDeleteSelected : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SliceCommandButton(
              label: 'Reset Slices',
              icon: Icons.restart_alt,
              onTap: widget.onReset,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _mapBody() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Text('First pad',
                style: TextStyle(
                    color: AutomationEditorTheme.labelMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            DropdownButton<int>(
              isDense: true,
              value: widget.firstNote,
              underline: const SizedBox.shrink(),
              dropdownColor: AutomationEditorTheme.panelBackground,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              items: [24, 36, 48, 60]
                  .map((note) => DropdownMenuItem(
                      value: note, child: Text(_midiNoteName(note))))
                  .toList(),
              onChanged: (value) {
                if (value != null) widget.onFirstNoteChanged(value);
              },
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'Exports the current slice regions upward from ${_midiNoteName(widget.firstNote)}.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                height: 1.3,
                color: AutomationEditorTheme.labelMuted.withValues(alpha: .9)),
          ),
          Expanded(
            child: Center(
              child: _SliceCommandButton(
                label: 'Send to Drum Machine',
                icon: Icons.grid_view_rounded,
                primary: true,
                onTap: widget.onExport,
              ),
            ),
          ),
        ],
      );
}
