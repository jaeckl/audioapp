<#
.SYNOPSIS
  Run synth DSP offline bench N times on PC and phone; aggregate medians.
#>
param(
    [int]$Runs = 20,
    [string]$DeviceId = "ZY32MCWDJ6",
    [int]$SampleRate = 48000,
    [int]$BlockSize = 512,
    [int]$Warmup = 20,
    [int]$Iterations = 80,
    [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $RepoRoot "build\synth_bench_multi\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$pcBin = Join-Path $RepoRoot "build\engine\audioapp_dsp_benchmarks.exe"
$phoneBinLocal = Join-Path $RepoRoot "build\engine-android-arm64\audioapp_dsp_benchmarks"
$phoneBinRemote = "/data/local/tmp/audioapp_dsp_benchmarks"

if (-not (Test-Path $pcBin)) { Write-Error "Missing PC binary: $pcBin" }
if (-not (Test-Path $phoneBinLocal)) { Write-Error "Missing phone binary: $phoneBinLocal" }

$adb = "adb"
if ($env:LOCALAPPDATA) {
    $c = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $c) { $adb = $c }
}

Write-Host "Push phone binary..."
& $adb -s $DeviceId push $phoneBinLocal $phoneBinRemote | Out-Null
& $adb -s $DeviceId shell "chmod 755 $phoneBinRemote" | Out-Null

$benchArgs = @(
    "--synths",
    "--sample-rate", "$SampleRate",
    "--block-size", "$BlockSize",
    "--warmup", "$Warmup",
    "--iterations", "$Iterations"
)

function Invoke-OfflineRuns {
    param(
        [string]$Platform,
        [scriptblock]$Runner
    )
    $platformDir = Join-Path $OutDir $Platform
    New-Item -ItemType Directory -Path $platformDir -Force | Out-Null
    $raw = @()
    for ($i = 1; $i -le $Runs; $i++) {
        Write-Host "$Platform run $i/$Runs ..."
        $jsonLine = & $Runner
        if (-not $jsonLine) { Write-Error "$Platform run $i produced no JSON" }
        $path = Join-Path $platformDir ("run_{0:D2}.json" -f $i)
        Set-Content -Path $path -Value $jsonLine -Encoding utf8
        $raw += ($jsonLine | ConvertFrom-Json)
    }
    return $raw
}

$pcRuns = Invoke-OfflineRuns -Platform "pc" -Runner {
    & $pcBin @benchArgs
}

$phoneRuns = Invoke-OfflineRuns -Platform "phone" -Runner {
    & $adb -s $DeviceId shell "$phoneBinRemote $($benchArgs -join ' ')"
}

# Aggregate: for each scenario, collect medianUs across runs.
function Aggregate-Runs {
    param($Runs, [string]$Platform)
    $byScenario = @{}
    foreach ($run in $Runs) {
        foreach ($r in $run.results) {
            $key = [string]$r.scenario
            if (-not $byScenario.ContainsKey($key)) {
                $byScenario[$key] = [System.Collections.Generic.List[double]]::new()
            }
            $byScenario[$key].Add([double]$r.medianUs)
        }
    }
    $rows = @()
    foreach ($key in ($byScenario.Keys | Sort-Object)) {
        $vals = @($byScenario[$key] | Sort-Object)
        $n = $vals.Count
        $mean = ($vals | Measure-Object -Average).Average
        $median = $vals[[int][math]::Floor(($n - 1) / 2)]
        if ($n -ge 2 -and ($n % 2) -eq 0) {
            $median = ($vals[$n / 2 - 1] + $vals[$n / 2]) / 2.0
        }
        $min = $vals[0]
        $max = $vals[$n - 1]
        $p95 = $vals[[math]::Min($n - 1, [int][math]::Ceiling(0.95 * $n) - 1)]
        $variance = 0.0
        if ($n -gt 1) {
            foreach ($v in $vals) { $variance += ($v - $mean) * ($v - $mean) }
            $variance /= ($n - 1)
        }
        $stdev = [math]::Sqrt($variance)
        $budgetUs = 1e6 * $BlockSize / $SampleRate
        $rows += [ordered]@{
            platform = $Platform
            scenario = $key
            runs = $n
            meanMedianUs = [math]::Round($mean, 3)
            medianOfMediansUs = [math]::Round($median, 3)
            p95OfMediansUs = [math]::Round($p95, 3)
            minMedianUs = [math]::Round($min, 3)
            maxMedianUs = [math]::Round($max, 3)
            stdevUs = [math]::Round($stdev, 3)
            realtimeFactorMean = [math]::Round($budgetUs / $mean, 3)
        }
    }
    return $rows
}

$agg = @()
$agg += Aggregate-Runs -Runs $pcRuns -Platform "pc"
$agg += Aggregate-Runs -Runs $phoneRuns -Platform "phone"

$summary = [ordered]@{
    kind = "synth_bench_multi"
    sampleRate = $SampleRate
    blockSize = $BlockSize
    warmup = $Warmup
    iterations = $Iterations
    runs = $Runs
    aggregated = $agg
}
$summaryPath = Join-Path $OutDir "offline_aggregate.json"
($summary | ConvertTo-Json -Depth 6) | Set-Content -Path $summaryPath -Encoding utf8
Write-Host "Wrote $summaryPath"
Write-Output $summaryPath
