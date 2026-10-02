#Requires -Version 5.1
[CmdletBinding()]
param([string]$SourceDir = (Join-Path $PSScriptRoot '..\..\.local-install\Plugin-Market-rebuild'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$SourceDir = [IO.Path]::GetFullPath($SourceDir)
if (Test-Path -LiteralPath $SourceDir) { throw "Use an empty source directory: $SourceDir" }
git clone https://github.com/BetterNCM/Plugin-Market.git $SourceDir
if ($LASTEXITCODE) { throw 'Clone failed' }
Push-Location $SourceDir
try {
    git checkout 3ad8be7d6e21d87fc8c9e6858a297c0ede5a62f0
    if ($LASTEXITCODE) { throw 'Checkout failed' }
    git apply (Join-Path $PSScriptRoot 'plugin-market.patch')
    if ($LASTEXITCODE) { throw 'Patch failed' }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'plugin-market.package-lock.json') -Destination 'package-lock.json'
    npm.cmd ci --ignore-scripts --no-audit --no-fund
    if ($LASTEXITCODE) { throw 'Dependency installation failed' }
    npm.cmd run build:prod
    if ($LASTEXITCODE) { throw 'Build failed' }
} finally { Pop-Location }
$output = Join-Path $SourceDir 'PluginMarket.plugin'
[IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $SourceDir 'dist'), $output)
Get-FileHash -LiteralPath $output -Algorithm SHA256
Write-Output "Rebuilt package: $output"
