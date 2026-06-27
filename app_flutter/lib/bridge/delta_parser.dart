import 'dart:convert';

import 'package:xml/xml.dart';

/// Parse a delta XML string (from C++ XmlElement) into the same
/// Map<dynamic, dynamic> structure that [SnapshotStore.applyDeltaToSnapshot]
/// expects, so the existing merge logic works unchanged.
Map<dynamic, dynamic> parseDeltaXml(String xmlString) {
  final doc = XmlDocument.parse(xmlString);
  final delta = doc.rootElement;
  final out = <dynamic, dynamic>{};

  // fullRefresh — rare path (project load/undo)
  final fullRefreshAttr = delta.getAttribute('fullRefresh');
  if (fullRefreshAttr == '1') {
    out['fullRefresh'] = true;
    final fullJson = delta.getAttribute('fullSnapshot');
    if (fullJson != null && fullJson.isNotEmpty) {
      final decoded = jsonDecode(fullJson);
      if (decoded is Map) {
        out['fullSnapshot'] = decoded;
      }
    }
    return out;
  }

  // ── Track deltas ──
  final tracksElem = delta.findElements('tracks').firstOrNull;
  if (tracksElem != null) {
    final tracksList = <Map<dynamic, dynamic>>[];
    for (final trackElem in tracksElem.findElements('track')) {
      final track = <dynamic, dynamic>{};
      track['trackId'] = trackElem.getAttribute('trackId') ?? '';
      if (trackElem.getAttribute('trackAdded') == '1') track['trackAdded'] = true;
      if (trackElem.getAttribute('trackRemoved') == '1') track['trackRemoved'] = true;
      if (trackElem.getAttribute('trackSelected') == '1') track['trackSelected'] = true;

      final devicesElem = trackElem.findElements('devices').firstOrNull;
      if (devicesElem != null) {
        final devicesList = <Map<dynamic, dynamic>>[];
        for (final devElem in devicesElem.findElements('device')) {
          final device = <dynamic, dynamic>{};
          device['deviceId'] = devElem.getAttribute('deviceId') ?? '';
          if (devElem.getAttribute('deviceAdded') == '1') device['deviceAdded'] = true;
          if (devElem.getAttribute('deviceRemoved') == '1') device['deviceRemoved'] = true;

          final paramsElem = devElem.findElements('params').firstOrNull;
          if (paramsElem != null) {
            final paramsList = <Map<dynamic, dynamic>>[];
            for (final pElem in paramsElem.findElements('param')) {
              final param = <dynamic, dynamic>{};
              param['paramId'] = pElem.getAttribute('paramId') ?? '';
              final nv = pElem.getAttribute('newValue');
              param['newValue'] = nv != null ? double.parse(nv) : 0.0;
              paramsList.add(param);
            }
            device['params'] = paramsList;
          }

          devicesList.add(device);
        }
        track['devices'] = devicesList;
      }

      tracksList.add(track);
    }
    out['tracks'] = tracksList;
  }

  // ── Modulator deltas ──
  final modsElem = delta.findElements('modulators').firstOrNull;
  if (modsElem != null) {
    final modsList = <Map<dynamic, dynamic>>[];
    for (final modElem in modsElem.findElements('modulator')) {
      final mod = <dynamic, dynamic>{};
      final lfoIdStr = modElem.getAttribute('lfoId') ?? '0';
      mod['lfoId'] = int.parse(lfoIdStr);
      if (modElem.getAttribute('modulatorAdded') == '1') mod['modulatorAdded'] = true;
      if (modElem.getAttribute('modulatorRemoved') == '1') mod['modulatorRemoved'] = true;

      final paramsElem = modElem.findElements('params').firstOrNull;
      if (paramsElem != null) {
        final paramsList = <Map<dynamic, dynamic>>[];
        for (final pElem in paramsElem.findElements('param')) {
          final param = <dynamic, dynamic>{};
          param['param'] = pElem.getAttribute('param') ?? '';
          final nv = pElem.getAttribute('newValue');
          param['newValue'] = nv != null ? double.parse(nv) : 0.0;
          paramsList.add(param);
        }
        mod['params'] = paramsList;
      }

      modsList.add(mod);
    }
    out['modulators'] = modsList;
  }

  // ── Transport delta ──
  final transportElem = delta.findElements('transport').firstOrNull;
  if (transportElem != null) {
    final transport = <dynamic, dynamic>{};
    if (transportElem.getAttribute('bpmChanged') == '1') {
      transport['bpmChanged'] = true;
      transport['newBpm'] = int.parse(transportElem.getAttribute('newBpm') ?? '120');
    }
    if (transportElem.getAttribute('playingChanged') == '1') {
      transport['playingChanged'] = true;
      transport['newPlaying'] = transportElem.getAttribute('newPlaying') == '1';
    }
    if (transportElem.getAttribute('loopEnabledChanged') == '1') {
      transport['loopEnabledChanged'] = true;
      transport['newLoopEnabled'] = transportElem.getAttribute('newLoopEnabled') == '1';
    }
    if (transportElem.getAttribute('loopRegionStartChanged') == '1') {
      transport['loopRegionStartChanged'] = true;
      transport['newLoopRegionStart'] =
          double.parse(transportElem.getAttribute('newLoopRegionStart') ?? '0');
    }
    if (transportElem.getAttribute('loopRegionEndChanged') == '1') {
      transport['loopRegionEndChanged'] = true;
      transport['newLoopRegionEnd'] =
          double.parse(transportElem.getAttribute('newLoopRegionEnd') ?? '16');
    }
    if (transportElem.getAttribute('playheadChanged') == '1') {
      transport['playheadChanged'] = true;
      transport['newPlayhead'] =
          double.parse(transportElem.getAttribute('newPlayhead') ?? '0');
    }
    if (transportElem.getAttribute('recordArmedChanged') == '1') {
      transport['recordArmedChanged'] = true;
      transport['newRecordArmed'] = transportElem.getAttribute('newRecordArmed') == '1';
    }
    out['transport'] = transport;
  }

  return out;
}