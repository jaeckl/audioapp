# Builds Flutter web screenshot gallery and captures PNGs with Chrome.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$App = Join-Path $Root "app_flutter"
$Out = Join-Path $Root "docs/design/dynamics_fx/screenshots"
$Build = Join-Path $App "build/web_screenshot"
$Port = 8765

New-Item -ItemType Directory -Force -Path $Out | Out-Null

Push-Location $App
try {
  flutter build web -t lib/dynamics_fx_screenshot_main.dart -o build/web_screenshot --web-renderer canvaskit
} finally {
  Pop-Location
}

$Chrome = @(
  "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $Chrome) {
  throw "Chrome not found. Install Google Chrome to capture screenshots."
}

$Server = Start-Process -PassThru -WindowStyle Hidden python -ArgumentList @(
  "-m", "http.server", "$Port", "--directory", $Build
)

Start-Sleep -Seconds 2

function Capture-Section {
  param([string]$Name, [int]$Width, [int]$Height, [string]$Selector)
  $file = Join-Path $Out "$Name.png"
  $url = "http://127.0.0.1:$Port/"
  $args = @(
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--window-size=$Width,$Height",
    "--screenshot=$file",
    $url
  )
  & $Chrome @args | Out-Null
  Write-Host "Captured $Name -> $file"
}

try {
  # Full gallery (all sections)
  Capture-Section -Name "00_gallery" -Width 1600 -Height 2400

  # Individual crops via tall narrow window scrolled sections — use full page for now
  $sections = @(
    @{ Name = "01_device_picker_effects"; W = 480; H = 520 },
    @{ Name = "02_gate_detect"; W = 400; H = 340 },
    @{ Name = "03_compressor_comp"; W = 400; H = 340 },
    @{ Name = "04_expander_expand"; W = 400; H = 340 },
    @{ Name = "05_limiter_ceiling"; W = 400; H = 340 },
    @{ Name = "06_dynamics_chain_row"; W = 1520; H = 360 }
  )

  foreach ($s in $sections) {
    $file = Join-Path $Out "$($s.Name).png"
    # Element screenshot via CDP would be ideal; use JS scroll + clip for chain row only
    if ($s.Name -eq "06_dynamics_chain_row") {
      & $Chrome @(
        "--headless=new", "--disable-gpu",
        "--window-size=$($s.W),$($s.H)",
        "--screenshot=$file",
        "http://127.0.0.1:$Port/#chain"
      ) | Out-Null
    }
  }

  Write-Host "Screenshots written to $Out"
} finally {
  if ($Server -and -not $Server.HasExited) {
    Stop-Process -Id $Server.Id -Force -ErrorAction SilentlyContinue
  }
}
