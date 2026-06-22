param([string]$TestName = 'device_chain_test')

# Step gate: compile + link + run a single test file.
# Uses a .rsp response file to dodge the 8 KB cmd line limit.

$ErrorActionPreference = 'Stop'

$root = (Get-Item (Join-Path $PSScriptRoot '..')).FullName
Set-Location $root

$vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
$compileDb = Join-Path $root 'build\engine\compile_commands.json'
$outDir = Join-Path $root 'build\engine\test_gate'
$src = Join-Path $root "engine_juce\tests\$TestName.cpp"
$obj = Join-Path $outDir "$TestName.obj"
$exe = Join-Path $outDir "$TestName.exe"
$lib = Join-Path $root 'build\engine\audioapp_engine.lib'
$rsp = Join-Path $outDir "$TestName.rsp"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$entry = (Get-Content $compileDb | ConvertFrom-Json | Where-Object { $_.file -like "*$TestName.cpp" } | Select-Object -First 1)
if ($null -eq $entry) { Write-Host "FAIL: no compile entry for $TestName"; exit 1 }

# Build a .rsp file with one flag per line. Strip -c (we'll add it explicitly).
$cmd = $entry.command
$flags = $cmd.Substring($cmd.IndexOf('cl.exe') + 6)
$tokens = @()
$sb = [System.Text.StringBuilder]::new()
$inQuote = $false
foreach ($c in $flags.ToCharArray()) {
    if ($c -eq '"') { $inQuote = -not $inQuote; [void]$sb.Append('"'); continue }
    if ($c -eq ' ' -and -not $inQuote) {
        if ($sb.Length -gt 0) { $tokens += $sb.ToString().Trim(); [void]$sb.Clear() }
        continue
    }
    [void]$sb.Append($c)
}
if ($sb.Length -gt 0) { $tokens += $sb.ToString().Trim() }

$srcNorm = $src.Replace('\', '\\')
$kept = @()
foreach ($t in $tokens) {
    if ($t -eq '/c') { continue }
    if ($t -match '^/Fo') { continue }
    if ($t -match '^/Fd') { continue }
    if ($t -eq $srcNorm -or $t -eq $src) { continue }
    $kept += $t
}
$kept += '/c'
$kept += "/Fo`"$obj`""
$kept += '/Fd'
$kept += "`"$src`""

Set-Content -Path $rsp -Value ($kept -join "`n") -Encoding ASCII

Write-Host "=== Step gate: compile $TestName.cpp ==="
$bat = Join-Path $outDir 'compile.bat'
$batBody = "@echo off`r`ncall `"$vcvars`" >nul 2>&1`r`ncl.exe @`"$rsp`"`r`n"
Set-Content -Path $bat -Value $batBody -Encoding ASCII
& cmd /c $bat 2>&1 | Select-Object -Last 25
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: compile exit $LASTEXITCODE"; exit 1 }
if (-not (Test-Path $obj)) { Write-Host "FAIL: $obj not produced"; exit 1 }

Write-Host "=== link ==="
$linkBat = Join-Path $outDir 'link.bat'
$linkBody = "@echo off`r`ncall `"$vcvars`" >nul 2>&1`r`nlink.exe /nologo /OUT:`"$exe`" `"$obj`" `"$lib`" kernel32.lib user32.lib`r`n"
Set-Content -Path $linkBat -Value $linkBody -Encoding ASCII
& cmd /c $linkBat 2>&1 | Select-Object -Last 10
if ($LASTEXITCODE -ne 0) { Write-Host "FAIL: link exit $LASTEXITCODE"; exit 1 }

Write-Host "=== run $TestName ==="
& $exe
$rc = $LASTEXITCODE
Write-Host "=== exit: $rc ==="
exit $rc