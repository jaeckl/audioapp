# Test Contract: Clip Resize

## C++ tests (engine_juce/tests/clip_length_test.cpp — modify existing)

### Existing tests (verify they still pass, no changes needed)

- `ClipLengthTest::Setup and basic snapshot checks` — unchanged
- `ClipLengthTest::set clip notes and shorten length` — unchanged
- `ClipLengthTest::activeMidiPitchAtBeat with shortened clip` — unchanged
- `ClipLengthTest::clip length clamped to minimum` — unchanged

### New tests

#### Test C1: SetAutomationClipLength

```cpp
beginTest("set automation clip length");
{
    auto project = std::make_unique<audioapp::ProjectEngine>();
    project->createProject();

    const std::string trackId = project->addTrack("Keys");
    const std::string clipId = project->createAutomationClip(trackId, 0.0, 4.0);
    project->assignAutomationTarget(clipId, "dev1", "gain");

    expect(project->setClipLength(clipId, 8.0),
           "setClipLength on automation clip returns true");

    const auto snap = project->snapshot();
    const auto* track = snap.findTrack(trackId);
    expect(track != nullptr);
    expect(!track->automationClips.empty());
    expectWithinAbsoluteError(track->automationClips[0].lengthBeats, 8.0, 0.001);
}
```

#### Test C2: SetAutomationClipLengthClamped

```cpp
beginTest("automation clip length clamped to minimum");
{
    auto project = std::make_unique<audioapp::ProjectEngine>();
    project->createProject();

    const std::string trackId = project->addTrack("Keys");
    const std::string clipId = project->createAutomationClip(trackId, 0.0, 4.0);

    expect(project->setClipLength(clipId, 0.001),
           "setClipLength on automation clip returns true");

    const auto snap = project->snapshot();
    const auto* track = snap.findTrack(trackId);
    expectWithinAbsoluteError(track->automationClips[0].lengthBeats, 0.01, 0.001,
                              "automation clip length clamped to 0.01");
}
```

#### Test C3: SetSampleClipLength

```cpp
beginTest("set sample clip length");
{
    auto project = std::make_unique<audioapp::ProjectEngine>();
    project->createProject();

    const std::string trackId = project->addTrack("Keys");
    // createSampleClip requires a sample bank; use existing test helpers
    project->createSampleClip(trackId, "sample-1", 0.0, 4.0);

    const auto snap = project->snapshot();
    if (snap.tracks.empty() || snap.tracks[0].sampleClips.empty()) return;
    const std::string clipId = snap.tracks[0].sampleClips[0].id;

    expect(project->setClipLength(clipId, 6.0),
           "setClipLength on sample clip returns true");

    const auto updated = project->snapshot();
    expectWithinAbsoluteError(updated.tracks[0].sampleClips[0].lengthBeats, 6.0, 0.001);
}
```

#### Test C4: UnknownClipIdReturnsFalse

```cpp
beginTest("unknown clip id returns false");
{
    auto project = std::make_unique<audioapp::ProjectEngine>();
    project->createProject();

    expect(!project->setClipLength("nonexistent-clip", 4.0),
           "setClipLength on unknown id returns false");
}
```

## Flutter widget tests (app_flutter/test/arrangement_view_resize_test.dart — new file)

### Setup

- Create a test harness with `MaterialApp` wrapping `ArrangementView` with a mock snapshot containing:
  - One track with one MIDI clip (startBeat=0, lengthBeats=4)
  - One track with one sample clip (startBeat=0, lengthBeats=4)
  - One track with one automation clip (startBeat=0, lengthBeats=4)
- Use a mock `EngineBridge` stub that records the last `setClipLength` call
- Wrap in `MaterialApp` with `Locale` / theme as needed

### Tests

#### Test F1: ResizeHandleRendered

- Find `_ClipResizeHandle` widgets in the tree for each clip type
- Verify exactly 3 handles are rendered (one per clip per track)
- Verify handle is positioned at the right edge of each clip block

#### Test F2: DragRightIncreasesLength

- Find the MIDI clip's resize handle
- Simulate long-press start on handle center
- Simulate long-press move 128 pixels to the right (64px/beat = 2 beats)
- Verify `previewLengthBeats` updated to 6.0 (original 4.0 + 2.0)
- Verify clip width Widget increased

#### Test F3: DragLeftDecreasesLength

- Find the MIDI clip's resize handle
- Simulate long-press start on handle center
- Simulate long-press move 64 pixels to the left (64px/beat = 1 beat)
- Verify `previewLengthBeats` updated to 3.0 (original 4.0 - 1.0)

#### Test F4: SnapsToBeatGrid

- Find the MIDI clip's resize handle
- Drag right 80 pixels (1.25 beats) — should snap to 1-beat grid
- Verify `previewLengthBeats` is 5.0 (not 5.25)

#### Test F5: ClampsToMinimumLength

- Find the MIDI clip's resize handle
- Drag left 300 pixels
- Verify `previewLengthBeats` is clamped to `kMinClipLengthBeats` (0.25)

#### Test F6: ClampsToAdjacentClip

- Create a track with a MIDI clip at startBeat=0, lengthBeats=4, and another clip at startBeat=8
- Resize first clip to the right
- Verify preview length clamps to 8.0 (adjacent clip start)

#### Test F7: CommitsCorrectLength

- Drag MIDI clip resize handle right 128 pixels
- Release (long-press end)
- Verify `onResizeClipCommit` called with `clipId` and `lengthBeats` = 6.0
- Verify `_resizeSession` is null after commit

#### Test F8: CancelRevertsLength

- Start resize drag, move pointer
- Cancel gesture
- Verify `_resizeSession` is null
- Verify clip width is back to original

#### Test F9: ResizeDoesNotTriggerClipDrag

- Find the resize handle on a clip
- Start long-press on the handle
- Verify `_clipDrag` remains null (existing clip drag session is not activated)

#### Test F10: AutomationClipResize

- Find automation clip's resize handle
- Drag right 128 pixels
- Verify preview length updated
- Verify release commits correct length

#### Test F11: SampleClipResize

- Find sample clip's resize handle
- Drag right 64 pixels
- Verify preview length updated
