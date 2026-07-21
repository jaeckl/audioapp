part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildcontentOperation on _DeviceStripSlotState {
  Widget _buildContent(BuildContext context) {
    // ignore: avoid_print
    print(
        'SLOT BUILD: device=${widget.device.type} _modStripVisible=$_modStripVisible _selectedLfo=$_selectedLfo _selectedLfoId=$_selectedLfoId');
    return DeviceStripTheme.wrapFrozenPreGainDimmed(
      dimmed: widget.track.isPreGainDeviceDimmed(widget.device),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          0,
          _collapsed
              ? DeviceStripTheme.collapsedSlotTopPadding
              : DeviceStripTheme.slotVerticalPadding,
          0,
          DeviceStripTheme.slotVerticalPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = constraints.maxHeight;
            if (_collapsed) {
              return SizedBox(
                width: _slotWidth,
                height: cardHeight,
                child: GestureDetector(
                  onLongPress: widget.onDeleteRequest,
                  child: DeviceStripCard(
                    deviceType: widget.device.type,
                    subtitle: _cardSubtitle,
                    headerOnly: true,
                    bodyHeight: 0,
                    child: const SizedBox.shrink(),
                  ),
                ),
              );
            }

            final innerHeight =
                cardHeight - DeviceStripTheme.cardBorderWidth * 2;
            final bodyHeight = innerHeight - DeviceStripTheme.cardChromeHeight;

            // Dynamically compute modulation grid width from current LFO count.
            // ModulationGrid sits outside the card — its total height = cardHeight.
            double modGridWidthLocal = 0;
            if (_modStripVisible) {
              const outerPad = ModulationGrid.outerPadding;
              const gap = ModulationGrid.cellGap;
              const rows = ModulationGrid.rowCount;
              const maxCount = ModulatorTypes.maxCount;
              // Label section in grid: Padding(top:4, bottom:cellGap) + fontSize 9 ~ 13px line height
              const labelH = 4.0 + 13.0 + ModulationGrid.cellGap;
              // Expanded → LayoutBuilder → constraints.maxHeight = cardHeight - labelH
              // Inside LayoutBuilder: padding bottom = outerPad → contentH = avail - outerPad
              final availH = cardHeight - labelH;
              final contentH = availH - outerPad;
              final cellSize = ((contentH - gap * (rows - 1)) / rows)
                  .clamp(0.0, double.infinity);
              final lfoCount = _localLfos.length;
              // _slots() pads to complete each column (3 items per col).
              int totalSlots;
              if (lfoCount >= maxCount) {
                totalSlots = lfoCount;
              } else {
                final rem = lfoCount % rows;
                final fill =
                    rem == 0 ? math.min(rows, maxCount - lfoCount) : rows - rem;
                totalSlots = lfoCount + fill;
              }
              final totalCols = (totalSlots + rows - 1) ~/ rows;
              // Last column is narrow (1/3 width) when it contains only add buttons.
              final hasNarrowCol = lfoCount % rows == 0 && lfoCount < maxCount;
              final fullColCount = hasNarrowCol ? totalCols - 1 : totalCols;
              modGridWidthLocal = outerPad * 2 +
                  fullColCount * cellSize +
                  (hasNarrowCol ? cellSize / 3 : 0) +
                  gap * (totalCols - 1);
            }

            return EffectiveParameterScope(
              deviceId: widget.device.id,
              child: SizedBox(
                width: _slotWidth + modGridWidthLocal - _modGridWidth,
                height: cardHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DeviceToolRail(
                      deviceName: DeviceStripTheme.labelForDeviceType(
                          widget.device.type),
                      accentColor: DeviceStripTheme.accentForDeviceType(
                          widget.device.type),
                      bypassed: widget.device.bypassed,
                      showLibrary: widget.onOpenLibrary != null,
                      libraryTooltip: 'Device presets',
                      onBypassToggle: widget.onBypassToggle ?? () {},
                      bypassModulationActive:
                          _modulatedParamIds.contains('bypass'),
                      bypassAutomationActive:
                          _automatedParamIds.contains('bypass'),
                      bypassConnectModeActive: _connectModeLfo != null,
                      bypassLinkModeActive: widget.automationLinkActive,
                      onBypassModulationAssign: _connectModeLfo == null
                          ? null
                          : _onBypassModulationAssign,
                      onBypassAutomationLinkTap:
                          widget.onAutomationParamSelected == null
                              ? null
                              : () => _onAutomationLinkTap('bypass'),
                      onAutomateBypass: widget.onAutomateParameter == null
                          ? null
                          : () => _onAutomateParameter('bypass'),
                      onDelete: widget.onDeleteRequest,
                      onLibrary: widget.onOpenLibrary != null
                          ? () => widget.onOpenLibrary!(
                              libraryFilterForDeviceType(widget.device.type))
                          : null,
                      reorderDragData: widget.reorderDragData,
                      modActive: _modStripVisible,
                      onModToggle: () async {
                        if (!_modStripVisible && _localLfos.isEmpty) {
                          // Auto-create first LFO so the strip isn't empty
                          await _onBridgeCall(
                            'createLfo',
                            {'deviceId': widget.device.id},
                          );
                          if (!mounted) return;
                        }
                        setState(() => _modStripVisible = !_modStripVisible);
                      },
                    ),
                    if (_modStripVisible)
                      SizedBox(
                        width: modGridWidthLocal,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Color(0xFF14141C),
                          ),
                          child: _modulationSidebar(),
                        ),
                      ),
                    if (_modStripVisible &&
                        _showTargetsPanel &&
                        _selectedLfo != null)
                      _targetsPanel(_targetsPanelLfo!),
                    if (_modStripVisible && _selectedLfo != null)
                      _buildModulatorPropertiesPanel(_selectedLfo!, bodyHeight),
                    if (_inputWidth > 0)
                      SizedBox(
                        width: _inputWidth,
                        child: _meterAwareChromePanel(
                          (bindings) =>
                              DeviceStripChrome.inputPanel(
                                deviceType: widget.device.type,
                                bindings: bindings,
                              ) ??
                              const SizedBox.shrink(),
                        ),
                      ),
                    SizedBox(
                      width: _cardWidth,
                      child: DeviceStripCard(
                        deviceType: widget.device.type,
                        subtitle: _cardSubtitle,
                        attachToolRail: true,
                        attachInputPanel: _inputWidth > 0,
                        attachOutputPanel: _outputWidth > 0,
                        tabs: _containerTabs,
                        selectedTabIndex: _selectedTabIndex,
                        onTabSelected: _onTabSelected,
                        headerActions: _deviceHeaderActions,
                        bodyHeight: bodyHeight,
                        child: _buildDevice(context, bodyHeight),
                      ),
                    ),
                    if (_outputWidth > 0)
                      SizedBox(
                        width: _outputWidth,
                        child: _meterAwareChromePanel(
                          (bindings) => DeviceStripChrome.outputPanel(
                            deviceType: widget.device.type,
                            bindings: bindings,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
