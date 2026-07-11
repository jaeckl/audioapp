part of 'device_strip_slot.dart';

extension DeviceStripSlotStateModulationsidebarOperation
    on _DeviceStripSlotState {
  Widget _modulationSidebar() {
    Widget gridFor(double beat) => ModulationGrid(
          lfos: _localLfos,
          selectedLfoId: _selectedLfoId,
          maxLfos: ModulatorTypes.maxCount,
          connectModeLfoId: _connectModeLfoId,
          playheadBeat: beat,
          bpm: widget.bpm,
          playing: widget.playing,
          onLfoTap: _onLfoTap,
          onLfoLongPress: _onLfoLongPress,
          onAddModulator: (type) =>
              _onBridgeCall('createLfo', {'modulatorType': type}),
          onRemoveLfo: (id) => _onBridgeCall('removeLfo', {'lfoId': id}),
          targetsPanelVisible: _showTargetsPanel,
          onShowTargets: (id) {
            setState(() {
              _selectedLfoId = id;
              _showTargetsPanel = true;
            });
          },
          onHideTargets: (id) {
            setState(() {
              if (_selectedLfoId == id) _selectedLfoId = null;
              _showTargetsPanel = false;
            });
          },
        );

    final listenable = widget.playheadBeatListenable;
    if (listenable == null) {
      return gridFor(widget.playheadBeat);
    }
    return ValueListenableBuilder<double>(
      valueListenable: listenable,
      builder: (context, beat, _) => gridFor(beat),
    );
  }
}
