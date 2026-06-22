# Windows local Android development

Recommended setup for this project on Windows (no dev container required).

This document covers **everything** you need to compile, test, and deploy the
mobile DAW (`audioapp`) on a Windows machine, with a physical Android phone
as the target device.

---

## 0. TL;DR for agents (read this first)

If you are an automated agent about to run a CMake / Ninja command on Windows,
stop and answer these three questions **before** running anything:

1. Did the current PowerShell session already run `vcvars64.bat`?
   - **No** → run it first (exact command in §3.1). Do not skip this.
2. After `vcvars64.bat`, does `where cl.exe` return a path under
   `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\`?
   - **No** → you are still on MinGW / Clang. Remove MinGW from PATH and
     re-run `vcvars64.bat`. See §13.
3. Is `build/engine-msvc/` the build directory you are using?
   - **No** → use `build/engine-msvc/`, **not** `build/engine/`.
     The latter is contaminated with Linux GCC cache.

**If any answer is "no", do not run `cmake` or `ninja`.** Fix the env first.

The exact sequence in one copy-paste block:

```powershell
# Step 1 (MANDATORY): activate MSVC in this shell
& "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

# Step 2 (MANDATORY): verify MSVC is now the compiler
where cl.exe        # MUST show MSVC's cl.exe, NOT gcc/MinGW/clang
where ninja.exe     # MUST show Ninja (not a gcc wrapper)

# Step 3: configure + build
cmake -S engine_juce -B build/engine-msvc -G Ninja -DCMAKE_BUILD_TYPE=Debug -DAUDIOAPP_BUILD_TESTS=ON
cmake --build build/engine-msvc --target audioapp_juce_tests

# Step 4: run the tests
.\build\engine-msvc\Debug\audioapp_juce_tests.exe
```

If `where cl.exe` after step 1 returns anything from `MinGW\`, `Git\mingw64\`,
`msys\`, `clang\`, or `gcc\` — **stop**, do not proceed, fix PATH (§13).

---

## 1. Toolchain overview

The mobile DAW is a monorepo with three subprojects:

| Subproject | Role | Toolchain |
|------------|------|-----------|
| `app_flutter/` | Android UI (Flutter / Dart) | Flutter SDK + Android SDK + NDK |
| `engine_juce/` | C++ audio engine (JUCE 8) | CMake + Ninja + **MSVC** (C++20) |
| `native_bridge/` | JNI bridge between Dart and the engine | Android NDK (built by Flutter Gradle) |

The "backend" is the local native engine — there is no server.

### Required installed components

| Tool | Where to install | Purpose |
|------|------------------|---------|
| Flutter 3.32.x | `C:\Users\ludwi\flutter` | UI + Android build orchestration |
| Android Studio (optional) | winget `AndroidStudio` | AVD Manager, SDK Manager, Logcat UI |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk` | platform-tools, build-tools 34+, NDK 26.x |
| Emulator AVD `audioapp_pixel` | Pixel 6, API 35 x86_64 (KVM required on host) | UI layout testing only |
| VS 2022 Build Tools | `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools` | MSVC `cl.exe` / `link.exe` for engine builds |
| Ninja | `%LOCALAPPDATA%\Programs\ninja` (add to user PATH) | fast CMake generator |
| CMake 3.22+ | `C:\Program Files\CMake\bin` | engine build configuration |
| ADB | `%LOCALAPPDATA%\Android\Sdk\platform-tools` | install / launch / log on device |

User environment variables (already set on this machine):

- `ANDROID_HOME` / `ANDROID_SDK_ROOT` → Android SDK
- `PATH` includes Flutter `bin`, `platform-tools`, `emulator`, Ninja

> **Restart Cursor** (or open a new terminal) so PATH changes apply after install.

---

## 2. Verify toolchain

```powershell
flutter doctor -v
cmake --version
ninja --version
adb version
```

Expected highlights:

- Flutter `3.32.4`, Dart `3.8.x`
- CMake `3.22.x` or newer
- Ninja `1.10+`
- ADB lists your phone as `device` (see §6 for connection troubleshooting)

```powershell
adb devices
# Expected:
# ZY32MCWDJ6    device
```

---

## 3. Build the native C++ engine (host / Windows MSVC)

> **STOP — read §0 first.** This section assumes you ran `vcvars64.bat` in
> the current shell. If you did not, the commands below WILL fail or fall
> back to MinGW / Clang.

The JUCE engine builds natively on Windows using **MSVC** — MinGW is **not**
supported (JUCE 8 needs C++20 features that MinGW's libstdc++ lacks).

### 3.1 Activate MSVC (mandatory, every fresh terminal)

`cl.exe` is **not** on `PATH` by default in PowerShell. You must run
`vcvars64.bat` once at the start of every fresh terminal session before
running any CMake / Ninja command. It sets `VCINSTALLDIR`, `INCLUDE`, `LIB`,
and prepends MSVC's `bin` to `PATH` so that `cl.exe` becomes the default C++
compiler.

```powershell
# Activate MSVC in the CURRENT shell (must be run from a regular PowerShell,
# not from inside `cmd.exe` or a non-interactive shell).
& "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
```

After this, your prompt shows environment variables set. **Do not skip this.**

If the path above does not exist on the machine, locate the file with:

```powershell
Get-ChildItem -Recurse -Path "C:\Program Files (x86)\Microsoft Visual Studio" -Filter vcvars64.bat
Get-ChildItem -Recurse -Path "C:\Program Files\Microsoft Visual Studio"     -Filter vcvars64.bat
```

and substitute the discovered path into the `&` command.

### 3.2 Verify MSVC is active (mandatory gate)

Run these checks **immediately after** `vcvars64.bat`. If any of them
fails, do not proceed — the build will silently fall back to the wrong
compiler.

```powershell
# MUST show MSVC's cl.exe
where cl.exe
# Expected (example):
#   C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.40.x\bin\Hostx64\x64\cl.exe

# MUST show Ninja from CMake/Ninja install, NOT a gcc shim
where ninja.exe
# Expected (example):
#   C:\Users\ludwi\AppData\Local\Programs\ninja\ninja.exe

# MUST show a non-empty VCINSTALLDIR
echo $env:VCINSTALLDIR
# Expected (example):
#   C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC

# MUST show MSVC's cl.exe FIRST in PATH, before any MinGW / Git / msys dir
$env:PATH -split ";" | Select-String -Pattern "Visual Studio|MSVC|MSBuild|BuildTools" | Select-Object -First 3
$env:PATH -split ";" | Select-String -Pattern "mingw|msys|git\\mingw|clang"     | Select-Object -First 3
# The first command MUST print ≥1 line. The second MUST print NOTHING.
```

**If `where cl.exe` returns any path containing `MinGW`, `mingw64`, `msys`,
`Git\mingw`, `clang`, or `gcc` — stop, remove those dirs from `PATH`, restart
PowerShell, and start over.** See §13 for the cleanup recipe.

### 3.3 Configure + build

Only run these after §3.2 passes.

```powershell
# Configure (from repo root). IMPORTANT: build into build/engine-msvc/, NEVER build/engine/.
cmake -S engine_juce -B build/engine-msvc -G Ninja -DCMAKE_BUILD_TYPE=Debug -DAUDIOAPP_BUILD_TESTS=ON

# Build the engine library only
cmake --build build/engine-msvc --target audioapp_engine

# Build the engine + the JUCE test executable
cmake --build build/engine-msvc --target audioapp_juce_tests
```

First configure fetches **JUCE 8.0.4** over the network (~200 MB); subsequent
configures are instant.

Output:

- `build/engine-msvc/audioapp_engine.lib` — static engine lib
- `build/engine-msvc/Debug/audioapp_juce_tests.exe` — JUCE UnitTest runner

> **Why `build/engine-msvc` and not `build/engine`?**
> The existing `build/engine/` directory was originally created by GCC on
> Linux and is committed in `.gitignore`-adjacent state. Use a fresh
> `build/engine-msvc/` (or any non-default name) to keep MSVC artifacts
> separate and avoid CMake cache contamination between compilers. **Never
> let CMake auto-pick a compiler** by omitting `-DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl` — if you do, and MinGW is on `PATH`, CMake will silently choose it.

### 3.4 Run the engine tests

```powershell
# All tests (suite run)
.\build\engine-msvc\Debug\audioapp_juce_tests.exe

# A single test by name (substring match)
.\build\engine-msvc\Debug\audioapp_juce_tests.exe ClipLength
.\build\engine-msvc\Debug\audioapp_juce_tests.exe "Automation Sampler Filter Sweep"

# List available test names
.\build\engine-msvc\Debug\audioapp_juce_tests.exe --list-tests
```

The runner prints one line per test:

```
RUNNING TEST RUNNER FOR: ClipLength
ClipLength: 0 failures
```

Pass / fail is determined by **0 failures**. Memory-leak dumps at exit are
harmless on Windows Debug builds (JUCE's `juce::String` allocations leak
intentionally under MSVC debug heap by default).

### 3.5 If you forgot §3.1 — the symptoms

A failed or wrong-compiler engine build typically looks like this in the
CMake configure output. If you see any of these, jump back to §3.1.

| Symptom | Cause | Fix |
|---------|-------|-----|
| `The C++ compiler ... is not able to compile a simple test program` (with `gcc` or `g++` mentioned) | MinGW picked up | §3.1 + §13 |
| `error: 'std::format' is not a member of 'std'` | MinGW's libstdc++ lacks C++20 `format` | §3.1 |
| `error: cannot find -lasound` on Windows | GCC picked up (ALSA is Linux-only) | §3.1 |
| `undefined reference to juce::*` (linker errors after a "successful" compile) | Wrong ABI between MSVC and MinGW object files | Delete `build/engine-msvc/`, rerun §3.1 + §3.3 |
| `cmake` prints `-- The C compiler identification is GNU` | MinGW / gcc on PATH ahead of MSVC | §13 |

> **MinGW is not supported.** If you have a previous MinGW install, remove it
> from `PATH` before building the engine — its `c++`/`cc` alternatives break
> JUCE 8's CMake config.

---

## 4. Build the Flutter Android app

The Flutter app pulls in the native engine through CMake (Gradle's external
native build). No pre-built engine artifact is needed — Gradle runs CMake for
you during the APK build.

### Build a debug APK

```powershell
cd app_flutter
flutter pub get
flutter build apk --debug
```

Output:

- `app_flutter/build/app/outputs/flutter-apk/app-debug.apk`

First build downloads NDK 26.x and CMake 3.22.1 into Gradle's cache (~2 GB,
one-time). Subsequent builds are incremental and typically finish in 15–60 s.

### Run with hot reload (preferred for development)

```powershell
cd app_flutter
flutter devices
flutter run -d <device-id>          # or omit -d to auto-pick the only phone
```

While the debug session is attached:

- edit any Dart file → save → press `r` in the terminal to hot-reload
- press `R` to hot-restart (keeps native state, resets Dart VM)
- press `q` to detach (the installed APK stays)

### Build a release APK

```powershell
cd app_flutter
flutter build apk --release          # signed with the debug key (dev only)
flutter build apk --release --split-per-abi   # smaller per-arch APKs
```

Release builds strip assertions and use `AOT` Dart compilation. For real
distribution you must set up an upload keystore (`android/key.properties`).

### Build for other targets

```powershell
flutter build appbundle --release    # .aab for Play Store
flutter build apk --debug --target-platform=android-arm64
flutter build apk --debug --target-platform=android-x64     # emulator only
flutter build web                    # web preview (no audio engine)
```

---

## 5. Deploy to a physical phone (fastest path)

This is the **preferred** path for audio testing — emulators under Windows
hypervisor have no GPU-accelerated audio, and the VM's TCG fallback is too
slow for real-time.

### One-shot install

```powershell
cd app_flutter
flutter build apk --debug -d ZY32MCWDJ6
adb -s ZY32MCWDJ6 install -r build\app\outputs\flutter-apk\app-debug.apk
```

Or use the helper script (same logic, but always picks up the latest APK):

```powershell
.\tools\flutter_deploy.ps1
```

### Background debug session (hot reload while you code)

```powershell
# One-time per session: keeps `flutter run` attached to the phone
.\tools\flutter_dev.ps1
```

This is what Cursor hooks run automatically at end of each agent session.

### Why the drawer icon shows an old build

Opening the app from the phone's app drawer runs the **installed APK**, not a
detached `flutter run`. If you changed Dart code and didn't rebuild, the
drawer icon will be stale. Always run `flutter_deploy.ps1` (or `flutter run`)
to refresh it.

---

## 6. Phone not in `adb devices` (troubleshooting)

Run the diagnostic script first:

```powershell
.\tools\adb_phone_check.ps1
```

### Motorola Moto — USB tethering blocks ADB (common on this machine)

If Windows shows **Remote NDIS based Internet Sharing Device** or an extra
**Ethernet** adapter when the phone is plugged in, the phone is in
**USB tethering** mode — not ADB mode.

**Fix on the phone:**

1. Turn **off** USB tethering / hotspot → USB sharing.
2. Notification shade → USB → **File transfer (MTP)**.
3. **Developer options** → USB debugging **ON**.
4. **Revoke USB debugging authorizations** → unplug → replug → tap **Allow**
   on the RSA prompt.

`adb devices` should then show `ZY32MCWDJ6    device`.

### Driver (if still no ADB interface)

Google's bundled `android_winusb.inf` does **not** list Motorola (VID `22B8`).
If Device Manager shows the phone without **Android ADB Interface**:

1. Download [Motorola Device Manager / USB drivers](https://en-us.support.motorola.com/app/answers/detail/a_id/88481).
2. Or in Device Manager → moto device → Update driver → browse to  
   `%LOCALAPPDATA%\Android\Sdk\extras\google\usb_driver`  
   and pick **Android ADB Interface** (may require adding VID/PID to the
   INF — see [TracerPlus guide](https://support.tracerplus.com/hc/en-us/articles/360050832033)).

### Wireless debugging (Android 11+)

Same Wi-Fi as the PC:

1. Developer options → **Wireless debugging** → Pair device with pairing code.
2. `adb pair <ip>:<pairing-port>` then `adb connect <ip>:<debug-port>`.
3. `flutter run` works the same once `adb devices` lists it.

---

## 7. Run Flutter tests + lint

```powershell
cd app_flutter
flutter test                        # 51 widget / bridge unit tests
flutter analyze                     # 0 errors (pre-existing info / warnings)
```

Flutter tests mock the native engine via `MethodChannel`, so they run without
the engine DLL being present.

---

## 8. Manual test — emulator (UI layout only)

Audio behaves differently on emulator vs hardware, so use it for layout / UX
iteration only.

```powershell
emulator -avd audioapp_pixel        # wait for home screen
cd app_flutter
flutter run                         # auto-picks the emulator
```

Or launch from **Android Studio → Device Manager** (GUI).

**Cold boot issues:** `adb kill-server` then `adb start-server`, or wipe AVD
data in Device Manager.

---

## 9. End-to-end development loop (cheat sheet)

```powershell
# One-time per session: open a new PowerShell and activate MSVC
& "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

# --- Engine work ---
cmake -S engine_juce -B build/engine-msvc -G Ninja -DCMAKE_BUILD_TYPE=Debug -DAUDIOAPP_BUILD_TESTS=ON
cmake --build build/engine-msvc --target audioapp_juce_tests
.\build\engine-msvc\Debug\audioapp_juce_tests.exe ClipLength

# --- Flutter work (in a separate terminal, no MSVC env needed) ---
cd app_flutter
flutter pub get
flutter run -d ZY32MCWDJ6

# --- One-shot rebuild + reinstall ---
cd app_flutter
flutter build apk --debug -d ZY32MCWDJ6
adb -s ZY32MCWDJ6 install -r build\app\outputs\flutter-apk\app-debug.apk
```

---

## 10. Headless dev container (optional)

Useful for Linux-only CI parity. **Not recommended** as the primary Windows
workflow because USB debugging and emulator GPU acceleration are simpler on
the host. The container has no KVM, so x86_64 emulator images fall back to
software TCG (too slow / crashes `system_server`) and `arm64-v8a` images are
rejected outright.

---

## 11. Android Studio role

You do **not** need Android Studio open for daily `flutter run`. Use it for:

- Device Manager / AVD creation
- SDK updates (SDK Manager)
- Inspecting native / Android logs when debugging the bridge (Logcat)

---

## 12. Toolchain locations (quick reference)

| Path | Contents |
|------|----------|
| `C:\Users\ludwi\flutter` | Flutter 3.32.4, Dart 3.8.1 |
| `%LOCALAPPDATA%\Android\Sdk` | Android SDK (platform 35, build-tools 35 + 34, NDK 26.3) |
| `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools` | MSVC compiler + linker |
| `C:\Program Files\CMake\bin` | CMake 3.22+ |
| `%LOCALAPPDATA%\Programs\ninja` | Ninja build generator |
| `C:\Program Files\Java\jdk-17` (or similar) | JDK 17 for Gradle |

---

## 13. Common pitfalls

### 13.1 Strip MinGW / Git's mingw / msys from PATH (the #1 cause of failed engine builds)

Git for Windows, MSYS2, Strawberry Perl, and some other installers drop a
`mingw64\bin` or `usr\bin` directory into your user `PATH` that ships its
own `gcc.exe`, `g++.exe`, and `ar.exe`. When you skip `vcvars64.bat` (or run
it in a shell that still has those dirs ahead of MSVC), CMake silently
picks `gcc` and the build "succeeds" with the wrong toolchain — but the
resulting `.lib` is incompatible with the Android NDK's MSVC build, and
the linker fails with cryptic `undefined reference to juce::*` errors.

**Inspect:**

```powershell
# Show every entry in PATH that contains mingw / msys / git / perl / strawberry
$env:PATH -split ";" |
    Where-Object { $_ -match "mingw|msys|git\\|perl\\|strawberry" } |
    ForEach-Object { $_ }
```

If this prints anything, follow one of the recipes below.

**Option A — fix the user PATH permanently (recommended):**

1. Win+R → `sysdm.cpl` → Advanced → Environment Variables.
2. Select `Path` under "User variables" → Edit.
3. Remove every entry matching `mingw`, `msys`, `Git\mingw64`, `Strawberry`,
   or `perl\site\bin`.
4. Click OK, OK, OK.
5. **Open a fresh PowerShell** (existing shells still have the old PATH
   cached). Run §3.1 and §3.2 again.

**Option B — strip MinGW from PATH only in the current shell (quick fix
that does not survive a restart):**

```powershell
# Run BEFORE `vcvars64.bat`. Removes any PATH component containing
# mingw / msys / git\mingw / strawberry / perl from the current shell only.
$env:PATH = ($env:PATH -split ";" |
    Where-Object { $_ -notmatch "mingw|msys|git\\mingw|strawberry|perl\\" }) -join ";"
& "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
where cl.exe    # must now show MSVC's cl.exe
```

**Option C — use an isolated clean shell:**

```powershell
# Launch a fresh PowerShell with PATH scrubbed of any MinGW/git mingw entries.
powershell.exe -NoProfile -Command {
    $env:PATH = ($env:PATH -split ";" |
        Where-Object { $_ -notmatch "mingw|msys|git\\mingw|strawberry|perl\\" }) -join ";"
    & "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    # Now drop into an interactive shell with the clean env:
    & cmd.exe /k
}
```

### 13.2 Other pitfalls

| Symptom | Cause | Fix |
|---------|-------|-----|
| `cmake` picks Clang / MinGW | `gcc`/`g++` not on PATH, or MinGW still on PATH | §13.1 |
| `cl.exe` not found after `vcvars64.bat` | Wrong VS install (Community vs BuildTools vs Preview) | Search with `Get-ChildItem -Recurse ... vcvars64.bat` (§3.1) |
| `error: 'std::format' is not a member of 'std'` | MinGW picked up (libstdc++ lacks C++20 `format`) | §13.1 |
| `error: cannot find -lasound` on Windows | GCC picked up (ALSA is Linux-only) | §13.1 |
| `undefined reference to juce::*` linker errors after a "successful" compile | Wrong ABI between MSVC and MinGW object files | Delete `build/engine-msvc/`, rerun §3.1 + §3.3 |
| `cmake` prints `-- The C compiler identification is GNU` | MinGW / gcc on PATH ahead of MSVC | §13.1 |
| `assertion failed: invalid comparator` in MSVC debug | `std::clamp` getting `NaN` from DSP | Already mitigated by `safe_clamp` wrappers in engine; if you write new DSP, never pass unfiltered values to `std::clamp` |
| `0xC0000005` access violation in a JUCE test | `expect()` called before `beginTest()` | Always call `beginTest("<name>")` at the top of every `runTest()` block before any `expect()` / `expectWithinAbsoluteError()` |
| Garbage strings in device test output | `DeviceRegistry` stored dangling `string_view` from temporary `typeId()` | Fixed by `std::vector<std::string> typeIds_` (committed). If you add a new device type, ensure `typeId()` returns a `string_view` to a static literal (never a temporary) |
| APK builds but app crashes on launch | Native engine linker mismatch | Run `flutter clean` then rebuild — NDK cache may be stale |
| `flutter doctor` complains about Android licenses | SDK packages not accepted | `flutter doctor --android-licenses` (accept all) |

---

## 14. Where things live

```
audioapp/
├── app_flutter/                  Flutter UI
│   ├── android/                  Gradle project (auto-builds native engine)
│   ├── lib/                      Dart sources
│   ├── test/                     Flutter widget / bridge tests
│   └── integration_test/         (placeholder; no on-device e2e tests yet)
├── engine_juce/                  C++ audio engine
│   ├── include/audioapp/         Public engine headers
│   ├── src/                      Engine implementation
│   └── tests/                    JUCE UnitTest sources (audioapp_juce_tests)
├── native_bridge/                JNI bridge (auto-built by Gradle)
├── tools/                        Helper PowerShell scripts
│   ├── flutter_dev.ps1           Background `flutter run`
│   ├── flutter_deploy.ps1        Build + install APK
│   └── adb_phone_check.ps1       Diagnose ADB connection
└── docs/
    ├── guidelines/
    │   └── windows_android_setup.md  ← this file
    └── features/<feature>/       Architecture contracts per feature
```