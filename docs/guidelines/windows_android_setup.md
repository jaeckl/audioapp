# Windows local Android development

Recommended setup for this project on Windows (no dev container required).

## Installed components

| Tool | Location |
|------|----------|
| Flutter | `C:\Users\ludwi\flutter` |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk` |
| Android Studio | Installed via winget (SDK UI, AVD Manager) |
| Emulator AVD | `audioapp_pixel` (Pixel 6, API 35 x86_64) |

User environment variables (already set):

- `ANDROID_HOME` / `ANDROID_SDK_ROOT` → Android SDK
- `PATH` includes Flutter `bin`, `platform-tools`, `emulator`

**Restart Cursor** (or open a new terminal) so PATH changes apply.

## Verify

```powershell
flutter doctor -v
adb devices
```

## Troubleshooting: phone not in `adb devices`

Run the diagnostic script:

```powershell
.\tools\adb_phone_check.ps1
```

### Motorola Moto — USB tethering blocks ADB (common)

If Windows shows **Remote NDIS based Internet Sharing Device** or an extra **Ethernet** adapter when the phone is plugged in, the phone is in **USB tethering** mode — not ADB mode.

**Fix on the phone:**

1. Turn **off** USB tethering / hotspot → USB sharing.
2. Notification shade → USB → **File transfer (MTP)**.
3. **Developer options** → USB debugging **ON**.
4. **Revoke USB debugging authorizations** → unplug → replug → tap **Allow** on the RSA prompt.

`adb devices` should then show `ZY32MCWDJ6    device` (your serial).

### Driver (if still no ADB interface)

Google’s bundled `android_winusb.inf` does **not** list Motorola (VID `22B8`). If Device Manager shows the phone without **Android ADB Interface**:

1. Download [Motorola Device Manager / USB drivers](https://en-us.support.motorola.com/app/answers/detail/a_id/88481) from Motorola.
2. Or in Device Manager → moto device → Update driver → browse to  
   `%LOCALAPPDATA%\Android\Sdk\extras\google\usb_driver`  
   and pick **Android ADB Interface** (may require adding VID/PID to the INF — see [TracerPlus guide](https://support.tracerplus.com/hc/en-us/articles/360050832033)).

## Manual test — physical device (best for audio)

This is the **preferred** way to test a DAW: real latency, real audio output, no emulator GPU quirks.

1. On the phone: **Settings → About phone** → tap Build number 7× to enable Developer options.
2. **Settings → Developer options** → enable **USB debugging**.
3. Connect USB. On the phone, tap **Allow** when asked to trust this computer.
4. In PowerShell:

```powershell
adb devices
```

You should see your device as `device` (not `unauthorized` or `offline`).

5. Run the app with hot reload:

```powershell
cd app_flutter
flutter run
```

Flutter picks the only connected Android device automatically. If multiple devices exist:

```powershell
flutter devices
flutter run -d <device-id>
```

6. While developing: save Dart files → hot reload (`r` in terminal) or hot restart (`R`).

### Wireless debugging (optional, Android 11+)

Same Wi‑Fi as the PC:

1. Developer options → **Wireless debugging** → Pair device with pairing code.
2. `adb pair <ip>:<pairing-port>` then `adb connect <ip>:<debug-port>`.
3. `flutter run` works the same once `adb devices` lists it.

### APK install without `flutter run`

```powershell
cd app_flutter
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

## Manual test — emulator

Useful for UI layout; audio may behave differently than on hardware.

**Start emulator:**

```powershell
emulator -avd audioapp_pixel
```

Wait until the home screen appears, then:

```powershell
cd app_flutter
flutter run
```

Or launch from **Android Studio → Device Manager** (GUI).

**Cold boot issues:** `adb kill-server` then `adb start-server`, or wipe AVD data in Device Manager.

## Android Studio role

You do **not** need Android Studio open for daily `flutter run`. Use it for:

- Device Manager / AVD creation
- SDK updates (SDK Manager)
- Inspecting native/Android logs when debugging the bridge (Logcat)

## Dev container

Optional for Linux-only CI parity. **Not recommended** as the primary Windows workflow because USB debugging and emulator GPU acceleration are simpler on the host.
