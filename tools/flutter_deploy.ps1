# Build debug APK and install to the connected phone (updates launcher icon build).
param(
    [string]$DeviceId = "",
    [int]$DebounceSeconds = 8
)

. "$PSScriptRoot\flutter_env.ps1"

if (-not (Test-Path $DevStateDir)) {
    New-Item -ItemType Directory -Path $DevStateDir -Force | Out-Null
}

$stampFile = Join-Path $DevStateDir "last_deploy.txt"
if (Test-Path $stampFile) {
    $last = [datetime]::Parse((Get-Content $stampFile -Raw))
    if (((Get-Date) - $last).TotalSeconds -lt $DebounceSeconds) {
        Write-Host "flutter_deploy: skipped (debounced)"
        exit 0
    }
}

if (-not $DeviceId) {
    $DeviceId = Get-AudioAppDeviceId
}

if (-not $DeviceId) {
    Write-Host "flutter_deploy: no Android device found"
    exit 1
}

Write-Host "flutter_deploy: installing to $DeviceId ..."
Set-Location $AppDir

& flutter build apk --debug
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& flutter install --debug -d $DeviceId
$code = $LASTEXITCODE

if ($code -eq 0) {
    Set-Content -Path $stampFile -Value (Get-Date).ToString("o")
    Write-Host "flutter_deploy: done"
}

exit $code
