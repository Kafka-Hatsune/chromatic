#Requires -Version 5.1
[CmdletBinding()]
param([string]$CloudMusicDir, [string]$ProfileDir, [switch]$Restart, [switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$CloudMusicDir = Resolve-CloudMusicDirectory $CloudMusicDir
$dataDir = Resolve-BetterNCMProfile $ProfileDir
$exe = Join-Path $CloudMusicDir 'cloudmusic.exe'
if (!(Test-Path -LiteralPath (Join-Path $CloudMusicDir 'msimg32.dll'))) { throw 'Install BetterNCM first.' }
if (!(Test-Path -LiteralPath $dataDir -PathType Container)) { throw 'Start BetterNCM once before installing this plugin.' }
$metadata = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'refined-romaji\package.json') -Raw | ConvertFrom-Json
$package = Join-Path $PSScriptRoot ('packages\' + $metadata.file)
if ((Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash -ne $metadata.sha256) { throw 'Plugin checksum mismatch. Download the complete repository again.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Read-PluginManifest([string]$Path) {
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entry = $archive.GetEntry('manifest.json')
        if (!$entry) { return $null }
        $reader = [IO.StreamReader]::new($entry.Open())
        try { return ($reader.ReadToEnd() | ConvertFrom-Json) } finally { $reader.Dispose() }
    } finally { $archive.Dispose() }
}
$manifest = Read-PluginManifest $package
if ($manifest.name -ne 'RefinedNowPlayingNext' -or $manifest.version -ne $metadata.version) { throw 'Unexpected plugin manifest.' }
$pluginDir = Join-Path $dataDir 'plugins'
$foundPlugins = @()
if (Test-Path -LiteralPath $pluginDir) {
    foreach ($file in Get-ChildItem -LiteralPath $pluginDir -Filter '*.plugin' -File) {
        try { $existing = Read-PluginManifest $file.FullName } catch { Write-Warning "Cannot read plugin: $($file.Name)"; continue }
        if ($existing.name -eq 'RefinedNowPlayingNext') { $foundPlugins += @{File=$file; Manifest=$existing} }
    }
}
if ($foundPlugins.Count -gt 1) { throw 'Multiple RefinedNowPlayingNext packages found. Keep only one active package before installing.' }
if ($foundPlugins.Count -eq 1 -and $foundPlugins[0].Manifest.version -notin @('3.0.2', $metadata.version)) {
    throw 'This build is based on RNP 3.0.2. Refusing to replace another version/fork automatically.'
}
$target = if ($foundPlugins.Count) { $foundPlugins[0].File.FullName } else { Join-Path $pluginDir $metadata.file }
if ($CheckOnly) { [pscustomobject]@{Target=$target;Version=$metadata.version;Checksum='OK';Action='Check only'}; return }
Stop-TargetCloudMusic $exe ([bool]$Restart)
$backup = Join-Path $PSScriptRoot ('backups\romaji-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
$hadPrevious = Test-Path -LiteralPath $target -PathType Leaf
if ($hadPrevious) { Copy-Item -LiteralPath $target -Destination (Join-Path $backup 'previous.plugin') }
Write-Utf8File (Join-Path $backup 'receipt.json') (@{CloudMusicDir=$CloudMusicDir;Profile=$dataDir;Target=$target;HadPrevious=[bool]$hadPrevious;InstalledSHA256=$metadata.sha256} | ConvertTo-Json)
Copy-Item -LiteralPath $package -Destination $target -Force
if ($Restart) { Start-Process -FilePath $exe -WorkingDirectory $CloudMusicDir -WindowStyle Hidden }
Write-Output "Installed RefinedNowPlayingNext $($metadata.version). Backup: $backup"
Write-Output 'In RNP settings > Lyrics, choose Romaji above Japanese kanji. Keep the reading display button enabled.'
