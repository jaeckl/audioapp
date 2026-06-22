$ErrorActionPreference = 'Stop'
$root = 'C:\Users\ludwi\Desktop\audioapp'
$compileDb = Join-Path $root 'build\engine\compile_commands.json'
$entry = (Get-Content $compileDb | ConvertFrom-Json | Where-Object { $_.file -like '*device_chain_test.cpp' } | Select-Object -First 1)
Write-Host "command length:" $entry.command.Length
Write-Host "first 200 chars:" $entry.command.Substring(0, 200)

$cmd = $entry.command
$flags = $cmd.Substring($cmd.IndexOf('cl.exe') + 6)
Write-Host "flags length:" $flags.Length
Write-Host "first 200 chars of flags:" $flags.Substring(0, [Math]::Min(200, $flags.Length))