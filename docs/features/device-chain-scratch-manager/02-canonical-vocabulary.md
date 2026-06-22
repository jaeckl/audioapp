# Canonical Vocabulary: DeviceChainScratchManager

## Purpose
Define precise, unambiguous naming for all concepts, types, and functions related to DeviceChainScratchManager. These names form the binding contract that implementation agents must follow exactly.

## Concept Table

| Concept | Canonical Name | Type/File | Notes |
|---------|---------------|-----------|-------|
| **Scratch Storage Management** | `DeviceChainScratchManager` | `include/audioapp/DeviceChainScratchManager.hpp` | Primary interface for thread-local scratch access |
| **Thread-Local Scratch Instance** | `gDeviceChainScratch` | `src/DeviceChainScratchManager.cpp` | Internal thread-local storage instance |
| **Scratch Data Structure** | `DeviceChainScratch` | `include/audioapp/DeviceChainScratchManager.hpp` | Container for all scratch arrays and regions |
| **Primary Audio Buffer** | `scratch` | `DeviceChainScratch` | Main processing buffer (kScratchFrames = 4096) |
| **Stereo Processing Buffers** | `tempStereoL`, `tempStereoR` | `DeviceChainScratch` | Left and right stereo temporary buffers |
| **Per-Frame Controls** | `perFrameGain`, `perFramePan` | `DeviceChainScratch` | Per-sample gain and pan control arrays |
| **Sampler Note Regions** | `samplerRegions` | `DeviceChainScratch` | Array of SamplerMidiNoteRegion structures |
| **Subtractive Synth Regions** | `subtractiveRegions` | `DeviceChainScratch` | Array of SubtractiveMidiNoteRegion structures |
| **Kick Generator Regions** | `kickRegions` | `DeviceChainScratch` | Array of KickMidiNoteRegion structures |
| **Snare Generator Regions** | `snareRegions` | `DeviceChainScratch` | Array of SnareMidiNoteRegion structures |
| **Clap Generator Regions** | `clapRegions` | `DeviceChainScratch` | Array of ClapMidiNoteRegion structures |
| **Cymbal Generator Regions** | `cymbalRegions` | `DeviceChainScratch` | Array of CymbalMidiNoteRegion structures |
| **Crash Generator Regions** | `crashRegions` | `DeviceChainScratch` | Array of CrashMidiNoteRegion structures |
| **Phase Mod Synth Regions** | `phaseModRegions` | `DeviceChainScratch` | Array of PhaseModSynthMidiNoteRegion structures |
| **Sampler Filter States** | `samplerNoteFilterStates` | `DeviceChainScratch` | Array of BiquadState structures |
| **Audio Peak Calculator** | `stereoBlockPeak` | `DeviceChainScratchManager` | Static utility function for peak detection |
| **Scratch Initializer** | `clearScratch` | `DeviceChainScratchManager` | Function to zero-initialize scratch buffers |
| **Thread Accessor** | `getScratch()` | `DeviceChainScratchManager` | Returns reference to thread-local scratch |
| **Buffer Size Constant** | `kScratchFrames` | `DeviceChainScratchManager` | Primary buffer size (4096) |
| **Max Instrument Regions** | `kMaxInstrumentRegions` | `DeviceChainScratchManager` | Maximum concurrent note regions (32) |
| **Audio Processing Block** | `framesToProcess` | `DeviceChainOrchestrator` | Runtime-determined processing size |
| **Per-Device Runtime** | `DynamicsRuntime`, `SubtractiveSynthRuntime`, etc. | Various | AudioThread-only state for devices |
| **Control vs Audio Thread** | `ControlThread`, `AudioThread` | Architecture docs | Threading model concept |
| **Immutable Snapshot** | `DeviceNodePlayback` | `DeviceChain.hpp` | Control-thread created, AudioThread consumed |

## Name Rules

### Binding Canonical Names
Implementation agents MUST use exactly these canonical names:

- `DeviceChainScratchManager` (class name)
- `DeviceChainScratch` (struct name)
- `gDeviceChainScratch` (thread-local instance)
- `getScratch()` (accessor function)
- `scratch` (primary buffer member)
- All other struct member names as listed in table above

### Forbidden Name Variants
Agents MUST NOT invent synonyms or alternatives:

❌ `scratchManager` (instead of `DeviceChainScratchManager`)
❌ `scratchSpace` (instead of `DeviceChainScratch`)
❌ `getScratchBuffer()` (private member, use `getScratch()` instead)
❌ `tempBuffers` (instead of `tempStereoL`/`tempStereoR`)
❌ `gainArray` (instead of `perFrameGain`)
❌ `panArray` (instead of `perFramePan`)
❌ `noteRegions` (instead of specific region types)
❌ `getScratchRef()` (instead of `getScratch()`)
❌ `scratchAccessor` (instead of `getScratch()`)

### Naming Conventions

#### Structs (Data Containers)
- Start with uppercase first letter
- Exactly as listed in Canonical Name column
- No abbreviations beyond what's in canonical names

#### Functions (Methods/Utilities)
- Start with lowercase first letter
- Exact names as listed
- No trailing underscores or suffixes

#### Constants
- `k` prefix for compile-time constants
- Exact names: `kScratchFrames`, `kMaxInstrumentRegions`

#### Files
- `DeviceChainScratchManager.hpp` - Interface
- `DeviceChainScratchManager.cpp` - Implementation
- `DeviceChainScratch.hpp` - Struct definition (if created)

## Type Synonyms and Aliases

### Forbidden Aliases
The following are BINDING canonical names - no substitutions allowed:

```cpp
// CORRECT
DeviceChainScratchManager::getScratch()

// INCORRECT (aliases not allowed)
scratchManager->getScratch()
getScratchSpace()
DeviceChainScratchManager::gScratch
```

### Union/Type References
```cpp
// CORRECT
using DeviceChainScratch = audioapp::DeviceChainScratch;

// INCORRECT
using ScratchSpace = DeviceChainScratch;
using ScratchBuffer = DeviceChainScratch;
```

## Function Signatures (Canonical)

### Accessor Methods
```cpp
// Primary access - MUST use exactly this signature
static DeviceChainScratch& getScratch() noexcept;

// Buffer accessors - MUST use exactly these signatures
static float* getScratchBuffer() noexcept;
static const float* getScratchBuffer() const noexcept;
static float* getTempStereoL() noexcept;
static float* getTempStereoR() noexcept;
static float* getPerFrameGain() noexcept;
static float* getPerFramePan() noexcept;

// Region accessors - MUST use exactly these signatures
static SamplerMidiNoteRegion* getSamplerRegions() noexcept;
static SubtractiveMidiNoteRegion* getSubtractiveRegions() noexcept;
static KickMidiNoteRegion* getKickRegions() noexcept;
static SnareMidiNoteRegion* getSnareRegions() noexcept;
static ClapMidiNoteRegion* getClapRegions() noexcept;
static CymbalMidiNoteRegion* getCymbalRegions() noexcept;
static CrashMidiNoteRegion* getCrashRegions() noexcept;
static PhaseModSynthMidiNoteRegion* getPhaseModRegions() noexcept;
static BiquadState* getSamplerFilterStates() noexcept;
```

### Utility Functions
```cpp
// MUST use exactly these signatures
static void clearScratch(int frames) noexcept;
static float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept;
```

## Constants and Enumeration

### Buffer Size Constants
```cpp
// MUST use exactly these constant names
constexpr int kScratchFrames = 4096;
constexpr int kMaxInstrumentRegions = 32;
constexpr int kAutomationSubBlockFrames = 64;
```

### Enumerations
```cpp
// Use existing DeviceNodeKind enum - no changes allowed
enum class DeviceNodeKind {
    Oscillator,
    Sampler,
    SubtractiveSynth,
    BassSynth,
    PhaseModSynth,
    KickGenerator,
    SnareGenerator,
    ClapGenerator,
    CymbalGenerator,
    CrashGenerator,
    Gate,
    Compressor,
    Expander,
    Limiter,
    TrackGain,
    Filter,
    FourBandEq,
    FrequencyShifter,
    Delay,
    Reverb,
    Chorus,
    Phaser,
    Unknown
};
```

## File Naming Rules

### Source Files
- `DeviceChainScratchManager.hpp` - Interface header
- `DeviceChainScratchManager.cpp` - Implementation source
- `DeviceChainScratch.hpp` - Struct definition (if created)

### Test Files
- `DeviceChainScratchManagerTest.hpp` - Test framework interface
- `DeviceChainScratchManagerTest.cpp` - Unit tests implementation

### Documentation Files
- `docs/features/device-chain-scratch-manager/00-feature-brief.md`
- `docs/features/device-chain-scratch-manager/01-architecture.md`
- `docs/features/device-chain-scratch-manager/02-canonical-vocabulary.md`
- `docs/features/device-chain-scratch-manager/03-api-contracts.md`
- `docs/features/device-chain-scratch-manager/04-data-contracts.md`
- `docs/features/device-chain-scratch-manager/05-file-ownership.md`
- `docs/features/device-chain-scratch-manager/06-vertical-work-packages.md`
- `docs/features/device-chain-scratch-manager/07-test-contract.md`
- `docs/features/device-chain-scratch-manager/08-integration-plan.md`

## Integration Naming Rules

### Cross-Package References
When multiple packages reference the same concept, use these canonical names:

```cpp
// Correct - use canonical name everywhere
auto& scratch = DeviceChainScratchManager::getScratch();
float* scratchBuffer = scratch.getScratchBuffer();

// INCORRECT - inventing alternative names
auto& scratchSpace = DeviceChainScratchManager::getScratch();
float* mainBuffer = scratch.getMainBuffer();
```

### Function Parameter Names
```cpp
// Correct - use canonical parameter names
static void myFunction(
    DeviceChainScratch& scratch,
    float* left,
    float* right,
    int frameCount
) noexcept;

// INCORRECT - inventing parameter names
static void myFunction(
    DeviceChainScratch& scratchArea,
    float* signalLeft,
    float* signalRight,
    int numSamples
) noexcept;
```

## Naming Enforcement

### Implementation Agent Requirements
1. **Exact Usage**: Must use exactly the canonical names specified
2. **No Synonyms**: Cannot create or use alternative names
3. **No Abbreviations**: Must use full names (e.g., `DeviceChainScratchManager` not `DCSM`)
4. **No Renaming**: Cannot rename any concept, struct, or function
5. **No Extensions**: Cannot add new parameters or modify signatures

### Consequences of Deviation
- Implementation rejected
- Must correct and resubmit
- Additional review time required
- May delay integration of entire vertical package

## Vocabulary Summary

### Core Vocabulary (Must Know)
1. `DeviceChainScratchManager` - Main interface class
2. `DeviceChainScratch` - Scratch data structure
3. `getScratch()` - Access thread-local scratch
4. `scratch`, `tempStereoL`, `tempStereoR`, `perFrameGain`, `perFramePan` - Main buffers
5. All region types (SamplerMidiNoteRegion, etc.) - Note storage
6. `stereoBlockPeak` - Peak detection utility
7. `clearScratch` - Buffer initialization
8. `kScratchFrames`, `kMaxInstrumentRegions` - Constants

### Extended Vocabulary (Should Know)
1. All specific buffer and region member names
2. All accessor function signatures
3. Utility function signatures
4. Constants and enumeration values
5. File naming conventions

### Vocabulary Growth (Implementation Detail)
Implementation agents may add helper functions and types as needed, but MUST:
- Use only canonical names for existing concepts
- Follow exact naming conventions outlined above
- Not create synonyms for existing canonical names
- Maintain backward compatibility with canonical contracts