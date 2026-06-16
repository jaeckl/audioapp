# Shared Flutter/Android paths for dev scripts (dot-source: . .\tools\flutter_env.ps1)

$script:FlutterSdk = if ($env:FLUTTER_ROOT) { $env:FLUTTER_ROOT } else { "C:\Users\ludwi\flutter" }
$script:AndroidSdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }
$script:RepoRoot = Split-Path $PSScriptRoot -Parent
$script:AppDir = Join-Path $RepoRoot "app_flutter"
$script:DevStateDir = Join-Path $RepoRoot ".flutter-dev"

$env:PATH = "$FlutterSdk\bin;$AndroidSdk\platform-tools;$AndroidSdk\emulator;" + $env:PATH

function Get-AudioAppDeviceId {
    param([string]$Preferred = "ZY32MCWDJ6")

    $devices = & adb devices | Select-String "device$" | ForEach-Object {
        ($_ -split "\s+")[0]
    }

    if ($Preferred -and ($devices -contains $Preferred)) {
        return $Preferred
    }

    foreach ($id in $devices) {
        if ($id -notmatch "^emulator-") {
            return $id
        }
    }

    if ($devices.Count -gt 0) {
        return $devices[0]
    }

    return $null
}
