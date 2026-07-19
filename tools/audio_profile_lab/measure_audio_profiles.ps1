#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Run on-device audio profile lab benchmark and summarize results.

.EXAMPLE
  .\tools\audio_profile_lab\measure_audio_profiles.ps1
  .\tools\audio_profile_lab\measure_audio_profiles.ps1 -Scenario parallel -PlaySeconds 30 -Deploy
  .\tools\audio_profile_lab\measure_audio_profiles.ps1 -Manual -PlaySeconds 60
#>
param(
    [string]$DeviceId = "ZY32MCWDJ6",
    [ValidateSet("light", "parallel", "serial_chain", "subtractive")]
    [string]$Scenario = "light",
    [int]$PlaySeconds = 20,
    [int]$SettleSeconds = 2,
    [int]$SampleMs = 500,
    [switch]$Deploy,
    [switch]$Manual,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$AppDir = Join-Path $RepoRoot "app_flutter"
$LabDir = $PSScriptRoot
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $LabDir "runs\$Timestamp"
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

. (Join-Path $RepoRoot "tools\flutter_env.ps1")

if (-not $DeviceId) {
    $DeviceId = Get-AudioAppDeviceId
}
if (-not $DeviceId) {
    Write-Error "No Android device found. Plug in the phone or pass -DeviceId."
}

Write-Host "audio_profile_lab: device=$DeviceId scenario=$Scenario output=$OutputDir"

$adb = "adb"
if ($env:LOCALAPPDATA) {
    $adbCandidate = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $adbCandidate) { $adb = $adbCandidate }
}

& $adb -s $DeviceId get-state 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "adb cannot reach $DeviceId. Run tools/adb_phone_check.ps1"
}

if ($Deploy) {
    & (Join-Path $RepoRoot "tools\flutter_deploy.ps1") -DeviceId $DeviceId
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$logcatPath = Join-Path $OutputDir "logcat.txt"
$flutterLogPath = Join-Path $OutputDir "flutter_test.log"
$jsonPath = Join-Path $OutputDir "summary.json"
$mdPath = Join-Path $OutputDir "summary.md"

if ($Manual) {
    Write-Host ""
    Write-Host "MANUAL SESSION" -ForegroundColor Cyan
    Write-Host "1. Open AudioApp on the phone."
    Write-Host "2. Load the project you want to stress-test."
    Write-Host "3. Settings -> Audio engine: run Low latency, Balanced, Safe."
    Write-Host "4. For each profile: press Play for at least $PlaySeconds seconds."
    Write-Host "5. Press Enter here when finished."
    Write-Host ""
    & $adb -s $DeviceId logcat -c | Out-Null
    $logcatJob = Start-Job -ScriptBlock {
        param($Adb, $Serial, $Path)
        & $Adb -s $Serial logcat -v time audioapp_engine:E audioapp_engine:I *:S |
            Tee-Object -FilePath $Path
    } -ArgumentList $adb, $DeviceId, $logcatPath
    Read-Host "Capturing logcat to $logcatPath. Press Enter to stop"
    Stop-Job $logcatJob | Out-Null
    Receive-Job $logcatJob | Out-Null
    Remove-Job $logcatJob | Out-Null
} else {
    & $adb -s $DeviceId logcat -c | Out-Null
    $logcatJob = Start-Job -ScriptBlock {
        param($Adb, $Serial, $Path)
        & $Adb -s $Serial logcat -v time audioapp_engine:E audioapp_engine:I *:S |
            Tee-Object -FilePath $Path
    } -ArgumentList $adb, $DeviceId, $logcatPath

    Push-Location $AppDir
    try {
        $defines = @(
            "--dart-define=LAB_SCENARIO=$Scenario",
            "--dart-define=LAB_PLAY_SECONDS=$PlaySeconds",
            "--dart-define=LAB_SETTLE_SECONDS=$SettleSeconds",
            "--dart-define=LAB_SAMPLE_MS=$SampleMs"
        )
        Write-Host "Running integration test on device..."
        & flutter test integration_test/audio_profile_lab_test.dart `
            -d $DeviceId `
            @defines 2>&1 | Tee-Object -FilePath $flutterLogPath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "flutter test failed. See $flutterLogPath"
        }
    } finally {
        Pop-Location
        Start-Sleep -Seconds 1
        Stop-Job $logcatJob | Out-Null
        Receive-Job $logcatJob | Out-Null
        Remove-Job $logcatJob | Out-Null
    }
}

$python = "python"
if (Get-Command python3 -ErrorAction SilentlyContinue) { $python = "python3" }
& $python (Join-Path $LabDir "parse_lab_output.py") `
    $flutterLogPath `
    $logcatPath `
    --output-json $jsonPath `
    --markdown $mdPath

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  JSON: $jsonPath"
Write-Host "  Markdown: $mdPath"
Write-Host "  Logcat: $logcatPath"
if (-not $Manual) {
    Write-Host "  Flutter log: $flutterLogPath"
}
