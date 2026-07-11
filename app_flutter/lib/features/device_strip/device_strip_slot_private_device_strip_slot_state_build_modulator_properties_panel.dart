part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildmodulatorpropertiespanelOperation
    on _DeviceStripSlotState {
  Widget _buildModulatorPropertiesPanel(
      LfoSnapshot snapshot, double bodyHeight) {
    final isEnvelope = snapshot.modulatorType == ModulatorTypes.envelope;
    final isRnd = snapshot.type == 'random_generator';
    final isSeq = snapshot.type == 'sequencer';
    final isCurve = snapshot.type == 'curve';

    // ignore: avoid_print
    print(
        'BUILD PROPERTIES PANEL: id=${snapshot.id} type=${snapshot.type} isSeq=$isSeq isRnd=$isRnd isEnvelope=$isEnvelope');

    double width = 260;
    Widget panel;

    Future<void> onUpdate(String param, double value) async {
      final updated = snapshot.applyParamUpdate(param, value);
      if (mounted) {
        setState(() {
          _localLfos =
              _localLfos.map((l) => l.id == updated.id ? updated : l).toList();
        });
      }
      await _onBridgeCall('updateLfoParam', {
        'lfoId': snapshot.id,
        'param': param,
        'value': value,
      });
    }

    if (isEnvelope) {
      width = 260;
      panel = EnvelopePropertiesPanel(
        key: ValueKey('env_panel_${snapshot.id}'),
        mod: snapshot,
        onUpdate: onUpdate,
      );
    } else if (isRnd) {
      width = 160;
      panel = RandomPropertiesPanel(
        key: ValueKey('rnd_panel_${snapshot.id}'),
        mod: snapshot,
        onUpdate: onUpdate,
      );
    } else if (isSeq) {
      width = 260;
      final isSync = snapshot.retrigger == ModulatorTypes.retriggerSync;
      panel = Container(
        color: const Color(0xFF14141C),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: _seqHeader(snapshot, onUpdate),
            ),
            const SizedBox(height: 8),
            // Step bars — fill remaining vertical space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SequencerStepEditor(
                  stepValues: snapshot.stepValues,
                  stepCount: snapshot.sequencerSteps,
                  onStepChanged: (i, v) => onUpdate('step_$i', v),
                  currentStep: null,
                ),
              ),
            ),
            // Bottom controls anchored at bottom
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Retrigger bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: _seqRetriggerBar(snapshot, onUpdate),
                ),
                // Sync divisions
                if (isSync)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: _seqSyncDivisions(snapshot, onUpdate),
                  ),
                // Knobs
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: _seqKnobs(snapshot, onUpdate),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (isCurve) {
      width = 260;
      panel = CurvePropertiesPanel(
        key: ValueKey('curve_panel_${snapshot.id}'),
        mod: snapshot,
        onUpdate: onUpdate,
        onOpenEditor: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CurveEditorScreen(
                mod: snapshot,
                onUpdate: onUpdate,
                onBatchUpdate: (params) async {
                  await _onBridgeCall('batchUpdateLfoParams', {
                    'lfoId': snapshot.id,
                    'params': params,
                  });
                },
              ),
            ),
          );
        },
      );
    } else {
      width = 260;
      panel = LfoPropertiesPanel(
        key: ValueKey('lfo_panel_${snapshot.id}'),
        mod: snapshot,
        onUpdate: onUpdate,
      );
    }

    return SizedBox(
      width: width,
      child: panel,
    );
  }
}
