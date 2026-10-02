#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Receipt, [switch]$Restart, [switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$receiptPath = (Resolve-Path -LiteralPath $Receipt).ProviderPath
$saved = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
$appDir = Resolve-CloudMusicDirectory $saved.CloudMusicDir
$dataDir = Resolve-BetterNCMProfile $saved.Profile
$pluginDir = [IO.Path]::GetFullPath((Join-Path $dataDir 'plugins')).TrimEnd('\')
$target = [IO.Path]::GetFullPath($saved.Target)
if ([IO.Path]::GetDirectoryName($target).TrimEnd('\') -ne $pluginDir -or [IO.Path]::GetExtension($target) -ne '.plugin') { throw 'Receipt target must be a plugin in this BetterNCM profile.' }
if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $saved.InstalledSHA256) { throw 'Plugin changed after this installation. Refusing to overwrite newer changes.' }
$previous = Join-Path (Split-Path $receiptPath) 'previous.plugin'
if ($saved.HadPrevious -and !(Test-Path -LiteralPath $previous -PathType Leaf)) { throw 'Original plugin backup is missing.' }
if ($CheckOnly) { [pscustomobject]@{Target=$target;RestorePrevious=[bool]$saved.HadPrevious;Action='Check only'}; return }
$exe = Join-Path $appDir 'cloudmusic.exe'
Stop-TargetCloudMusic $exe ([bool]$Restart)
if ($saved.HadPrevious) { Copy-Item -LiteralPath $previous -Destination $target -Force } else { Remove-Item -LiteralPath $target }
if ($Restart) { Start-Process -FilePath $exe -WorkingDirectory $appDir -WindowStyle Hidden }
Write-Output 'Restored the previous plugin package. Plugin settings and other plugins were preserved.'
