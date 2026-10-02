#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$CloudMusicDir,
    [string]$ProfileDir,
    [switch]$Restart,
    [switch]$MarketOnly,
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$CloudMusicDir = Resolve-CloudMusicDirectory $CloudMusicDir
$ProfileDir = Resolve-BetterNCMProfile $ProfileDir
$exe = Join-Path $CloudMusicDir 'cloudmusic.exe'
$cef = Join-Path $CloudMusicDir 'libcef.dll'
if ((Get-PeMachine $exe) -ne 0x8664 -or (Get-PeMachine $cef) -ne 0x8664) {
    throw 'This package requires x64 CloudMusic and x64 libcef.dll.'
}
$packageDir = Join-Path $PSScriptRoot 'packages'
$dll = Join-Path $packageDir 'BetterNCMII-1.3.4-x64.dll'
$market = Join-Path $packageDir 'PluginMarket.plugin'
$hashes = Get-Content -LiteralPath (Join-Path $packageDir 'sha256.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($file in @($dll, $market)) {
    $name = [IO.Path]::GetFileName($file)
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $hashes.$name) {
        throw "Package checksum mismatch: $name. Extract a fresh download."
    }
}
if ((Get-PeMachine $dll) -ne 0x8664) { throw 'Wrong BetterNCM DLL architecture.' }
$targetDll = Join-Path $CloudMusicDir 'msimg32.dll'
if ($MarketOnly) {
    if (!(Test-Path -LiteralPath $targetDll -PathType Leaf)) {
        throw 'MarketOnly requires an already installed, compatible BetterNCM loader.'
    }
} elseif ((Test-Path -LiteralPath $targetDll) -and
    (Get-FileHash -LiteralPath $targetDll -Algorithm SHA256).Hash -ne $hashes.'BetterNCMII-1.3.4-x64.dll') {
    throw 'Existing msimg32.dll is a different loader. It was not changed. Use -MarketOnly to keep it, or uninstall it with its own installer first.'
}
$version = (Get-Item -LiteralPath $exe).VersionInfo.FileVersion
Write-Host "CloudMusic: $exe ($version, x64)"
Write-Host "BetterNCM data: $ProfileDir"
if ($version -and $version -ne '3.1.41.205529') {
    Write-Warning 'Only CloudMusic 3.1.41.205529 x64 has been runtime-tested for this distribution.'
}
$configPath = Join-Path $ProfileDir 'config.json'
$config = @{}
if (Test-Path -LiteralPath $configPath) {
    $oldConfig = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($oldConfig -isnot [pscustomobject]) { throw 'config.json must contain a JSON object.' }
    foreach ($property in $oldConfig.PSObject.Properties) { $config[$property.Name] = $property.Value }
}
if ($CheckOnly) { Write-Output 'Preflight OK. No files or processes were changed.'; return }
Stop-TargetCloudMusic $exe ([bool]$Restart)
$backup = Join-Path $PSScriptRoot ('backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$files = @()
if (!$MarketOnly) { $files += $targetDll }
$files += (Join-Path $ProfileDir 'plugins\PluginMarket.plugin'), $configPath
$entries = @()
for ($i = 0; $i -lt $files.Count; $i++) {
    $exists = Test-Path -LiteralPath $files[$i]
    $saved = Join-Path $backup "$i.original"
    if ($exists) { Copy-Item -LiteralPath $files[$i] -Destination $saved }
    $entries += [ordered]@{ Path=$files[$i]; Existed=$exists; Backup=$saved; InstalledHash=$null }
}
$source = 'https://raw.githubusercontent.com/BetterNCM/BetterNCM-Packed-Plugins/master/'
$receipt = [ordered]@{
    Created=(Get-Date -Format o); CloudMusicExe=$exe; ProfileDir=$ProfileDir
    CloudMusicVersion=$version; MarketOnly=[bool]$MarketOnly
    OriginalExeHash=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
    OriginalCefHash=(Get-FileHash -LiteralPath $cef -Algorithm SHA256).Hash
    Source='https://github.com/std-microblock/chromatic/releases/tag/1.3.4'
    PluginSource=$source; Files=$entries
}
$receiptPath = Join-Path $backup 'receipt.json'
Write-Utf8File $receiptPath ($receipt | ConvertTo-Json -Depth 6)
try {
    New-Item -ItemType Directory -Path (Join-Path $ProfileDir 'plugins') -Force | Out-Null
    $config['cc.microblock.pluginmarket.source'] = $source
    Write-Utf8File $configPath ($config | ConvertTo-Json -Depth 30)
    Copy-Item -LiteralPath $market -Destination (Join-Path $ProfileDir 'plugins\PluginMarket.plugin') -Force
    if (!$MarketOnly) { Copy-Item -LiteralPath $dll -Destination $targetDll -Force }
    foreach ($entry in $entries) {
        $entry.InstalledHash = (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash
    }
    Write-Utf8File $receiptPath ($receipt | ConvertTo-Json -Depth 6)
} catch {
    foreach ($entry in $entries) {
        if ($entry.Existed) { Copy-Item -LiteralPath $entry.Backup -Destination $entry.Path -Force }
        elseif (Test-Path -LiteralPath $entry.Path) { Remove-Item -LiteralPath $entry.Path -Force }
    }
    throw
}
Write-Output "Installed. Keep this rollback receipt: $receiptPath"
if ($Restart) { Start-Process -FilePath $exe -WorkingDirectory $CloudMusicDir -WindowStyle Hidden }
