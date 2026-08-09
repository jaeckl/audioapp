param(
    [string]$DeviceId = "ZY32MCWDJ6",
    [int]$Runs = 20,
    [int]$PlaySeconds = 5,
    [int]$SettleSeconds = 1,
    [int]$SampleMs = 500,
    [string[]]$Scenarios = @("light", "subtractive", "wavetable", "phasemod", "granular"),
    [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$AppDir = Join-Path $RepoRoot "app_flutter"
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutDir = Join-Path $RepoRoot ("build\synth_bench_multi\{0}-profiles" -f $stamp)
}
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

. (Join-Path $RepoRoot "tools\flutter_env.ps1")

$adb = "adb"
if ($env:LOCALAPPDATA) {
    $candidate = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $candidate) { $adb = $candidate }
}

Write-Host ("profile multi-run: device={0} runs={1} play={2}s out={3}" -f $DeviceId, $Runs, $PlaySeconds, $OutDir)

Write-Host "Waking device and forcing stay-on (USB)..."
& $adb -s $DeviceId shell "input keyevent KEYCODE_WAKEUP" | Out-Null
& $adb -s $DeviceId shell "svc power stayon true" | Out-Null
& $adb -s $DeviceId shell "settings put system screen_off_timeout 1800000" | Out-Null
$wake = & $adb -s $DeviceId shell "dumpsys power | grep mWakefulness="
Write-Host ("power: {0}" -f $wake)
if (("$wake") -match "Dozing|Asleep") {
    Write-Warning "Device still Dozing/Asleep after wake. Unlock phone screen manually, then re-run."
}

$sentinel = "@@" + "AUDIO_PROFILE_LAB" + "@@"
$allReports = New-Object System.Collections.Generic.List[object]

foreach ($scenario in $Scenarios) {
    Write-Host ("=== scenario={0} ===" -f $scenario) -ForegroundColor Cyan
    $scenarioDir = Join-Path $OutDir $scenario
    New-Item -ItemType Directory -Path $scenarioDir -Force | Out-Null
    $flutterLog = Join-Path $scenarioDir "flutter_test.log"
    $logcatPath = Join-Path $scenarioDir "logcat.txt"

    & $adb -s $DeviceId logcat -c | Out-Null
    $logcatJob = Start-Job -ScriptBlock {
        param($AdbPath, $Serial, $Path)
        & $AdbPath -s $Serial logcat -v time audioapp_engine:E audioapp_engine:I *:S |
            Tee-Object -FilePath $Path
    } -ArgumentList $adb, $DeviceId, $logcatPath

    Push-Location $AppDir
    try {
        $defineArgs = @(
            ("--dart-define=LAB_SCENARIO={0}" -f $scenario),
            ("--dart-define=LAB_PLAY_SECONDS={0}" -f $PlaySeconds),
            ("--dart-define=LAB_SETTLE_SECONDS={0}" -f $SettleSeconds),
            ("--dart-define=LAB_SAMPLE_MS={0}" -f $SampleMs),
            ("--dart-define=LAB_RUNS={0}" -f $Runs)
        )
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($flutterLog, "", $utf8NoBom)
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $flutterExit = 0
        & flutter test integration_test/audio_profile_lab_test.dart -d $DeviceId --timeout 120m @defineArgs 2>&1 |
            ForEach-Object {
                $line = "$_"
                [System.IO.File]::AppendAllText($flutterLog, $line + [Environment]::NewLine, $utf8NoBom)
                Write-Host $line
            }
        $flutterExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEap
        if ($flutterExit -ne 0) {
            Write-Warning ("flutter test exit {0} for {1} (see {2})" -f $flutterExit, $scenario, $flutterLog)
        }
    }
    finally {
        Pop-Location
        Stop-Job $logcatJob -ErrorAction SilentlyContinue | Out-Null
        Receive-Job $logcatJob -ErrorAction SilentlyContinue | Out-Null
        Remove-Job $logcatJob -ErrorAction SilentlyContinue | Out-Null
    }

    # Keep screen awake between scenarios.
    & $adb -s $DeviceId shell "input keyevent KEYCODE_WAKEUP; svc power stayon true" | Out-Null

    $text = [System.IO.File]::ReadAllText($flutterLog)
    $idx = $text.LastIndexOf($sentinel)
    if ($idx -lt 0) {
        Write-Warning ("No lab sentinel for {0}" -f $scenario)
        continue
    }

    $payload = $text.Substring($idx + $sentinel.Length).Trim()
    $end = -1
    $depth = 0
    $started = $false
    for ($i = 0; $i -lt $payload.Length; $i++) {
        $ch = $payload[$i]
        if ($ch -eq [char]'{') {
            $depth++
            $started = $true
        }
        elseif ($ch -eq [char]'}') {
            $depth--
            if ($started -and $depth -eq 0) {
                $end = $i
                break
            }
        }
    }
    if ($end -lt 0) {
        Write-Warning ("Could not parse lab JSON for {0}" -f $scenario)
        continue
    }

    $json = $payload.Substring(0, $end + 1)
    $reportPath = Join-Path $scenarioDir "report.json"
    Set-Content -Path $reportPath -Value $json -Encoding utf8
    $allReports.Add(($json | ConvertFrom-Json))
    Write-Host ("saved {0}" -f $reportPath)
}

$aggRows = New-Object System.Collections.Generic.List[object]
foreach ($report in $allReports) {
    $byProfile = @{}
    foreach ($entry in $report.results) {
        $p = [string]$entry.profile
        if (-not $byProfile.ContainsKey($p)) {
            $byProfile[$p] = New-Object System.Collections.Generic.List[double]
            $byProfile[($p + "__xrun")] = New-Object System.Collections.Generic.List[double]
            $byProfile[($p + "__deadline")] = New-Object System.Collections.Generic.List[double]
        }
        [void]$byProfile[$p].Add([double]$entry.final.maxCallbackMicros)
        [void]$byProfile[($p + "__xrun")].Add([double]$entry.final.xRunCount)
        [void]$byProfile[($p + "__deadline")].Add([double]$entry.final.deadlineMicros)
    }
    foreach ($p in @("low_latency", "balanced", "safe")) {
        if (-not $byProfile.ContainsKey($p)) { continue }
        $vals = @($byProfile[$p] | Sort-Object)
        $n = $vals.Count
        $mean = ($vals | Measure-Object -Average).Average
        if (($n % 2) -eq 1) {
            $median = $vals[[int][math]::Floor($n / 2)]
        }
        else {
            $median = ($vals[($n / 2) - 1] + $vals[$n / 2]) / 2.0
        }
        $xruns = @($byProfile[($p + "__xrun")])
        $deadlines = @($byProfile[($p + "__deadline")])
        $deadlineMean = ($deadlines | Measure-Object -Average).Average
        $headroom = 0.0
        if ($deadlineMean -gt 0) {
            $headroom = [math]::Round(1.0 - ($mean / $deadlineMean), 4)
        }
        $row = [ordered]@{
            scenario = $report.scenario
            profile = $p
            runs = $n
            meanMaxCallbackUs = [math]::Round($mean, 1)
            medianMaxCallbackUs = [math]::Round($median, 1)
            minMaxCallbackUs = [math]::Round($vals[0], 1)
            maxMaxCallbackUs = [math]::Round($vals[$n - 1], 1)
            meanDeadlineUs = [math]::Round($deadlineMean, 1)
            meanHeadroomRatio = $headroom
            totalXRunsLastSampleSum = [math]::Round((($xruns | Measure-Object -Sum).Sum), 0)
        }
        [void]$aggRows.Add($row)
    }
}

$summary = [ordered]@{
    kind = "audio_profile_lab_multi"
    runs = $Runs
    playSeconds = $PlaySeconds
    settleSeconds = $SettleSeconds
    scenarios = $Scenarios
    aggregated = $aggRows
}
$summaryPath = Join-Path $OutDir "profile_aggregate.json"
($summary | ConvertTo-Json -Depth 6) | Set-Content -Path $summaryPath -Encoding utf8
Write-Host ("Wrote {0}" -f $summaryPath)
Write-Output $summaryPath
