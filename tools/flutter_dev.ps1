# Keep `flutter run` attached for hot reload (r/R) while developing.
param(
    [string]$DeviceId = ""
)

. "$PSScriptRoot\flutter_env.ps1"

if (-not (Test-Path $DevStateDir)) {
    New-Item -ItemType Directory -Path $DevStateDir -Force | Out-Null
}

if (-not $DeviceId) {
    $DeviceId = Get-AudioAppDeviceId
}

if (-not $DeviceId) {
    Write-Host "flutter_dev: no Android device found"
    exit 1
}

$pidFile = Join-Path $DevStateDir "flutter_run.pid"
if (Test-Path $pidFile) {
    $oldPid = [int](Get-Content $pidFile -Raw)
    if ($oldPid -gt 0 -and (Get-Process -Id $oldPid -ErrorAction SilentlyContinue)) {
        Write-Host "flutter_dev: already running (PID $oldPid) on $DeviceId"
        exit 0
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

$logFile = Join-Path $DevStateDir "flutter_run.log"
$errFile = Join-Path $DevStateDir "flutter_run.err.log"
Write-Host "flutter_dev: starting flutter run on $DeviceId (log: $logFile)"

Set-Location $AppDir

$proc = Start-Process -FilePath "flutter" `
    -ArgumentList @("run", "-d", $DeviceId) `
    -WorkingDirectory $AppDir `
    -RedirectStandardOutput $logFile `
    -RedirectStandardError $errFile `
    -PassThru `
    -WindowStyle Hidden

if (-not $proc) {
    Write-Host "flutter_dev: failed to start flutter run"
    exit 1
}

Set-Content -Path $pidFile -Value $proc.Id
Write-Host "flutter_dev: PID $($proc.Id). Hot reload: r, hot restart: R, quit: q (see log)"
