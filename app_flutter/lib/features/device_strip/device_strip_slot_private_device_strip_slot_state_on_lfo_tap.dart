part of 'device_strip_slot.dart';

extension DeviceStripSlotStateOnlfotapOperation on _DeviceStripSlotState {
  void _onLfoTap(int lfoId) {
    setState(() {
      if (_selectedLfoId == lfoId) {
        // Deselect — close panel too
        _selectedLfoId = null;
        _showTargetsPanel = false;
      } else {
        // Select different modulator, keep panel open if it was open
        _selectedLfoId = lfoId;
      }
    });
  }
}
