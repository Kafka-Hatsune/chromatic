#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$CloudMusicDir,
    [string]$ProfileDir,
    [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$PluginSlug = 'RefinedNowPlayingNext',
    [switch]$EnablePlugin
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$CloudMusicDir = Resolve-CloudMusicDirectory $CloudMusicDir
$dataDir = Resolve-BetterNCMProfile $ProfileDir
$exe = Join-Path $CloudMusicDir 'cloudmusic.exe'
if (!(Test-Path -LiteralPath $dataDir -PathType Container)) { throw "Missing BetterNCM profile: $dataDir" }
$path = Join-Path $dataDir 'disable_list.txt'
$lines = if (Test-Path -LiteralPath $path) { @([IO.File]::ReadAllLines($path)) } else { @() }
$backup = Join-Path $PSScriptRoot ('backups\recovery-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination (Join-Path $backup 'disable_list.txt') }
Write-Utf8File (Join-Path $backup 'receipt.json') (@{
    Plugin=$PluginSlug; Enable=[bool]$EnablePlugin; PreviousList=$lines; Profile=$dataDir
} | ConvertTo-Json -Depth 4)
$lines = @($lines | Where-Object { $_.Trim() -ne $PluginSlug })
if (!$EnablePlugin) { $lines += $PluginSlug }
Stop-TargetCloudMusic $exe $true
Write-Utf8File $path (($lines -join "`n") + "`n")
Start-Process -FilePath $exe -WorkingDirectory $CloudMusicDir -WindowStyle Hidden
Write-Output "$PluginSlug enabled: $([bool]$EnablePlugin). CloudMusic restarted. Plugin packages and user data preserved."
