$json = Get-Content 'build\engine\compile_commands.json' | ConvertFrom-Json
$matches = $json | Where-Object { $_.file -like '*device_chain_test.cpp' }
Write-Host "matches:" $matches.Count
foreach ($m in $matches) { Write-Host "  file:" $m.file "cmd-len:" $m.command.Length }