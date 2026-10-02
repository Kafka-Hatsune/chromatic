#Requires -Version 5.1
[CmdletBinding()]
param([string]$BuildRoot)
$ErrorActionPreference = 'Stop'
$rnpCommit = '167bffe62b57bd276fc6aa34237c4a197f56fa7d'
$readingCommit = 'b536d24b67a625dd4fc01a899e92da69a40cfb1f'
if (!$BuildRoot) { $BuildRoot = Join-Path $PSScriptRoot ('.build\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff')) }
if (Test-Path -LiteralPath $BuildRoot) { throw 'Use a new empty build directory.' }
Get-Command git -ErrorAction Stop | Out-Null
Get-Command node -ErrorAction Stop | Out-Null
Get-Command npm.cmd -ErrorAction Stop | Out-Null
New-Item -ItemType Directory -Path $BuildRoot -Force | Out-Null
$BuildRoot = (Resolve-Path -LiteralPath $BuildRoot).ProviderPath
$rnp = Join-Path $BuildRoot 'RefinedNowPlayingNext'
$reference = Join-Path $BuildRoot 'jp-furigana'
& git clone --quiet https://github.com/SUlTlUS/refined-now-playing-netease-next.git $rnp
if ($LASTEXITCODE) { throw 'RNP clone failed.' }
& git -C $rnp checkout --quiet --detach $rnpCommit
if ($LASTEXITCODE) { throw 'RNP source revision is unavailable.' }
& git clone --quiet https://github.com/Leleawa/jp-furigana.git $reference
if ($LASTEXITCODE) { throw 'Reading dependency clone failed.' }
& git -C $reference checkout --quiet --detach $readingCommit
if ($LASTEXITCODE) { throw 'Reading dependency revision is unavailable.' }
& git -C $rnp apply --check (Join-Path $PSScriptRoot 'refined-romaji.patch')
if ($LASTEXITCODE) { throw 'Source patch check failed.' }
& git -C $rnp apply (Join-Path $PSScriptRoot 'refined-romaji.patch')
if ($LASTEXITCODE) { throw 'Source patch failed.' }
$vendor = Join-Path $rnp 'vendor\japanese'
New-Item -ItemType Directory -Path $vendor -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $reference 'src\dict') -Destination $vendor -Recurse
foreach ($name in @('kuromoji.js','furigana.js','LICENSE','LICENSE-kuromoji.txt','NOTICE.md')) {
    Copy-Item -LiteralPath (Join-Path $reference ('src\' + $name)) -Destination $vendor
}
Copy-Item -LiteralPath (Join-Path $reference 'tools\patch-kuromoji.js') -Destination $vendor
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'refined-romaji.package-lock.json') -Destination (Join-Path $rnp 'package-lock.json')
Push-Location $rnp
try {
    & npm.cmd ci --ignore-scripts
    if ($LASTEXITCODE) { throw 'Dependency installation failed.' }
    & npm.cmd run build
    if ($LASTEXITCODE) { throw 'Build failed.' }
    & npm.cmd run test:kanji
    if ($LASTEXITCODE) { throw 'Reading tests failed.' }
} finally { Pop-Location }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$package = Join-Path $BuildRoot 'RefinedNowPlayingNext-3.0.2+romaji.1.plugin'
[IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $rnp 'dist'), $package)
Get-FileHash -LiteralPath $package -Algorithm SHA256
Write-Output "Built: $package"
