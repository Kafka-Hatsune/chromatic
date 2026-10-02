#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Receipt, [switch]$Restart)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$state = Get-Content -LiteralPath $Receipt -Raw -Encoding UTF8 | ConvertFrom-Json
if (!$state.CloudMusicExe -or !$state.ProfileDir -or !$state.Files) {
    throw 'Not an installation receipt. Select a timestamped installation receipt, not a recovery receipt.'
}
$exe = [IO.Path]::GetFullPath($state.CloudMusicExe)
$targetDll = [IO.Path]::GetFullPath((Join-Path (Split-Path $exe) 'msimg32.dll'))
$allowed = @(
    $targetDll,
    [IO.Path]::GetFullPath((Join-Path $state.ProfileDir 'plugins\PluginMarket.plugin')),
    [IO.Path]::GetFullPath((Join-Path $state.ProfileDir 'config.json'))
)
$preserve = @()
foreach ($entry in $state.Files) {
    if ([IO.Path]::GetFullPath($entry.Path) -notin $allowed) { throw "Unexpected restoration path: $($entry.Path)" }
    if ($entry.Existed -and !(Test-Path -LiteralPath $entry.Backup -PathType Leaf)) { throw "Missing backup: $($entry.Backup)" }
    if ((Test-Path -LiteralPath $entry.Path) -and $entry.InstalledHash -and
        (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash -ne $entry.InstalledHash) {
        if ([IO.Path]::GetFullPath($entry.Path) -eq $targetDll) {
            throw 'The loader DLL has changed since installation; review it before restoring.'
        }
        Write-Warning "Preserving a plugin/config file changed after installation: $($entry.Path)"
        $preserve += $entry.Path
    }
}
Stop-TargetCloudMusic $exe ([bool]$Restart)
foreach ($entry in $state.Files) {
    if ($entry.Path -in $preserve) { continue }
    if ($entry.Existed) { Copy-Item -LiteralPath $entry.Backup -Destination $entry.Path -Force }
    elseif (Test-Path -LiteralPath $entry.Path) { Remove-Item -LiteralPath $entry.Path -Force }
}
Write-Output 'Restored installation files. Other plugins and user data were preserved.'
if ($Restart) { Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden }
