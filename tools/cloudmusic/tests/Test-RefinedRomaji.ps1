#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$toolDir = Split-Path $PSScriptRoot
$fixture = Join-Path $toolDir ('backups\romaji-script-test-' + [guid]::NewGuid().ToString('N'))
$appDir = Join-Path $fixture 'app'
$dataDir = Join-Path $fixture 'profile'
$pluginDir = Join-Path $dataDir 'plugins'
foreach ($dir in @($appDir, $pluginDir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
# These are never executed; the test must not launch or stop a real music app.
foreach ($name in @('cloudmusic.exe', 'msimg32.dll')) { [IO.File]::WriteAllBytes((Join-Path $appDir $name), [byte[]]@()) }
$payload = Join-Path $fixture 'original'
New-Item -ItemType Directory -Path $payload | Out-Null
[IO.File]::WriteAllText((Join-Path $payload 'manifest.json'), '{"name":"RefinedNowPlayingNext","version":"3.0.2"}')
Add-Type -AssemblyName System.IO.Compression.FileSystem
$target = Join-Path $pluginDir 'original.plugin'
[IO.Compression.ZipFile]::CreateFromDirectory($payload, $target)
$originalHash = (Get-FileHash -LiteralPath $target).Hash
$previousEnvironment = [Environment]::GetEnvironmentVariable('BETTERNCM_PROFILE','Process')
try {
    [Environment]::SetEnvironmentVariable('BETTERNCM_PROFILE',$dataDir,'Process')
    & (Join-Path $toolDir 'Install-RefinedRomaji.ps1') -CloudMusicDir $appDir -ProfileDir $dataDir -CheckOnly | Out-Null
    if ((Get-FileHash -LiteralPath $target).Hash -ne $originalHash) { throw 'CheckOnly changed a file.' }
    & (Join-Path $toolDir 'Install-RefinedRomaji.ps1') -CloudMusicDir $appDir -ProfileDir $dataDir | Out-Null
    $receipt = Get-ChildItem -LiteralPath (Join-Path $toolDir 'backups') -Directory -Filter 'romaji-*' | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'receipt.json') } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $receiptPath = Join-Path $receipt.FullName 'receipt.json'
    $metadata = Get-Content -LiteralPath (Join-Path $toolDir 'refined-romaji\package.json') -Raw | ConvertFrom-Json
    if ((Get-FileHash -LiteralPath $target).Hash -ne $metadata.sha256) { throw 'Installed checksum mismatch.' }
    if (@(Get-ChildItem -LiteralPath $pluginDir -Filter '*.plugin').Count -ne 1) { throw 'Duplicate package installed.' }
    & (Join-Path $toolDir 'Restore-RefinedRomaji.ps1') -Receipt $receiptPath -CheckOnly | Out-Null
    & (Join-Path $toolDir 'Restore-RefinedRomaji.ps1') -Receipt $receiptPath | Out-Null
    if ((Get-FileHash -LiteralPath $target).Hash -ne $originalHash) { throw 'Rollback failed to restore original bytes.' }
    Write-Output 'PASS: dry run, replacement, checksum, single package, and byte-for-byte rollback.'
} finally { [Environment]::SetEnvironmentVariable('BETTERNCM_PROFILE',$previousEnvironment,'Process') }
