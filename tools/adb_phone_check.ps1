#!/usr/bin/env pwsh
# Diagnose why an Android phone is not visible to adb on Windows.

$SdkRoot = $env:LOCALAPPDATA + "\Android\Sdk"
$env:PATH = "$SdkRoot\platform-tools;$SdkRoot\emulator;" + $env:PATH

Write-Host "=== ADB devices ===" -ForegroundColor Cyan
adb kill-server 2>$null | Out-Null
adb start-server 2>&1
adb devices -l

Write-Host "`n=== Phone USB mode (Windows) ===" -ForegroundColor Cyan
$moto = Get-CimInstance Win32_PnPEntity | Where-Object { $_.DeviceID -match '22B8|ZY32' }
if (-not $moto) {
    Write-Host "No Motorola USB device detected. Is the phone plugged in?" -ForegroundColor Yellow
} else {
    $moto | Select-Object Name, PNPClass, Status, DeviceID | Format-Table -AutoSize -Wrap
}

$tether = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
    $_.InterfaceDescription -match 'Remote NDIS|RNDIS'
}
if ($tether) {
    Write-Host "PROBLEM: USB tethering is ON (RNDIS)." -ForegroundColor Red
    Write-Host "  Windows sees the phone as a network adapter, not ADB."
    Write-Host "  Fix: On the phone, turn OFF USB tethering / hotspot USB sharing."
    Write-Host "  Then set USB mode to File transfer (MTP)."
    $tether | Format-Table Name, Status, InterfaceDescription -AutoSize
}

$adbIface = Get-CimInstance Win32_PnPEntity | Where-Object {
    $_.Name -match 'ADB Interface|Android Composite|Android ADB'
}
if ($adbIface) {
    Write-Host "OK: Android ADB interface present in Device Manager:" -ForegroundColor Green
    $adbIface | Select-Object Name, Status, DeviceID | Format-Table -AutoSize -Wrap
} else {
    Write-Host "PROBLEM: No 'Android ADB Interface' in Device Manager." -ForegroundColor Red
    Write-Host "  USB debugging is off, wrong USB mode, or driver not installed."
}

Write-Host "`n=== Interpretation ===" -ForegroundColor Cyan
Write-Host @"
Expected when working:
  adb devices  ->  ZY32MCWDJ6    device
  Device Manager -> Android Composite ADB Interface (or similar)

Your phone serial (from earlier): ZY32MCWDJ6
Motorola VID: 22B8

If tethering is off and ADB still missing:
  1. Developer options -> USB debugging ON
  2. Revoke USB debugging authorizations -> replug USB
  3. Accept 'Allow USB debugging?' on phone
  4. Install Motorola / Google USB driver (see docs/guidelines/windows_android_setup.md)
"@
