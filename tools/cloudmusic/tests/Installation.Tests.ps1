#Requires -Version 5.1
# Real file transactions in an isolated fixture. Never launches CloudMusic.
$ErrorActionPreference = 'Stop'
$toolDir = Split-Path $PSScriptRoot
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('betterncm-install-test-' + [guid]::NewGuid().ToString('N'))
$appDir = Join-Path $testRoot 'app with spaces'
$dataDir = Join-Path $testRoot 'profile'
$sandboxTools = Join-Path $testRoot 'tools'
$previousProfile = $env:BETTERNCM_PROFILE
function Assert([bool]$Condition, [string]$Message) {
    if (!$Condition) { throw "ASSERTION FAILED: $Message" }
}
function Expect-Failure([scriptblock]$Action, [string]$Pattern) {
    $caught = $false
    try { & $Action } catch {
        if ($_.Exception.Message -notmatch $Pattern) { throw }
        $caught = $true
    }
    Assert $caught "Expected rejection matching $Pattern"
}
function Latest-Receipt {
    return (Get-ChildItem -LiteralPath (Join-Path $sandboxTools 'backups') -Filter receipt.json -Recurse |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1).FullName
}
try {
    New-Item -ItemType Directory -Path $appDir,$dataDir,$sandboxTools -Force | Out-Null
    Get-ChildItem -LiteralPath $toolDir -Filter '*.ps1' | Copy-Item -Destination $sandboxTools
    Copy-Item -LiteralPath (Join-Path $toolDir 'packages') -Destination $sandboxTools -Recurse
    $env:BETTERNCM_PROFILE = $dataDir
    $bytes = New-Object byte[] 512
    $bytes[0] = 0x4d; $bytes[1] = 0x5a; $bytes[0x3c] = 0x80
    $bytes[0x80] = 0x50; $bytes[0x81] = 0x45; $bytes[0x84] = 0x64; $bytes[0x85] = 0x86
    $exe = Join-Path $appDir 'cloudmusic.exe'
    $cef = Join-Path $appDir 'libcef.dll'
    [IO.File]::WriteAllBytes($exe, $bytes)
    [IO.File]::WriteAllBytes($cef, $bytes)
    $exeHash = (Get-FileHash -LiteralPath $exe).Hash
    $install = Join-Path $sandboxTools 'Install-BetterNCM.ps1'
    $restore = Join-Path $sandboxTools 'Restore-BetterNCM.ps1'
    $targetDll = Join-Path $appDir 'msimg32.dll'
    $configPath = Join-Path $dataDir 'config.json'
    $marketPath = Join-Path $dataDir 'plugins\PluginMarket.plugin'

    & $install -CloudMusicDir $appDir -CheckOnly
    Assert (!(Test-Path -LiteralPath $targetDll)) 'CheckOnly wrote the loader'
    Assert (!(Test-Path -LiteralPath (Join-Path $sandboxTools 'backups'))) 'CheckOnly wrote backups'

    & $install -CloudMusicDir $exe
    Assert ((Get-FileHash -LiteralPath $targetDll).Hash -eq (Get-FileHash -LiteralPath (Join-Path $sandboxTools 'packages\BetterNCMII-1.3.4-x64.dll')).Hash) 'Installed DLL differs'
    Assert (Test-Path -LiteralPath $marketPath) 'Market not installed'
    & $restore -Receipt (Latest-Receipt)
    Assert (!(Test-Path -LiteralPath $targetDll)) 'First installation did not roll back DLL'
    Assert (!(Test-Path -LiteralPath $configPath)) 'First installation did not roll back config'
    Assert (!(Test-Path -LiteralPath $marketPath)) 'First installation did not roll back market'

    [IO.File]::WriteAllText($targetDll, 'another-loader')
    Expect-Failure { & $install -CloudMusicDir $appDir } 'different loader'
    Assert ([IO.File]::ReadAllText($targetDll) -eq 'another-loader') 'Unknown loader was overwritten'
    Assert (!(Test-Path -LiteralPath $configPath)) 'Rejected install wrote config'

    [IO.File]::WriteAllText($configPath, '{"keep":42}')
    & $install -CloudMusicDir $appDir -MarketOnly
    Assert ([IO.File]::ReadAllText($targetDll) -eq 'another-loader') 'MarketOnly changed loader'
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    Assert ($config.keep -eq 42) 'Unrelated config lost'
    Assert ($config.'cc.microblock.pluginmarket.source' -like 'https://raw.githubusercontent.com/*') 'Source not configured'
    & $restore -Receipt (Latest-Receipt)
    Assert ([IO.File]::ReadAllText($configPath) -eq '{"keep":42}') 'Original config not restored'
    Assert ([IO.File]::ReadAllText($targetDll) -eq 'another-loader') 'Market-only rollback touched loader'

    & $install -CloudMusicDir $appDir -MarketOnly
    [IO.File]::WriteAllText($configPath, '{"laterEdit":true}')
    & $restore -Receipt (Latest-Receipt)
    Assert ([IO.File]::ReadAllText($configPath) -eq '{"laterEdit":true}') 'Later config edits were overwritten'

    Copy-Item -LiteralPath (Join-Path $sandboxTools 'packages\BetterNCMII-1.3.4-x64.dll') -Destination $targetDll -Force
    & $install -CloudMusicDir $appDir
    $receiptPath = Latest-Receipt
    [IO.File]::WriteAllText($targetDll, 'changed-after-install')
    Expect-Failure { & $restore -Receipt $receiptPath } 'loader DLL has changed'
    Assert ([IO.File]::ReadAllText($targetDll) -eq 'changed-after-install') 'Rollback changed a replaced loader'

    # Exercise the actual recovery script, replacing only process launch with a recorder.
    $launchRecord = @{ Path=$null; Count=0 }
    function Start-Process {
        param($FilePath, $WorkingDirectory, $WindowStyle)
        Assert ($FilePath -eq $exe) 'Recovery tried to launch an unexpected application'
        $launchRecord.Path = $FilePath
        $launchRecord.Count++
    }
    $disablePath = Join-Path $dataDir 'disable_list.txt'
    [IO.File]::WriteAllText($disablePath, "AnotherPlugin`n")
    $recover = Join-Path $sandboxTools 'Recover-CloudMusic.ps1'
    & $recover -CloudMusicDir $appDir
    & $recover -CloudMusicDir $appDir
    $disabled = @([IO.File]::ReadAllLines($disablePath) | Where-Object { $_ })
    Assert ($disabled.Count -eq 2 -and $disabled -contains 'AnotherPlugin' -and $disabled -contains 'RefinedNowPlayingNext') 'Recovery lost or duplicated disabled plugins'
    & $recover -CloudMusicDir $appDir -EnablePlugin
    Assert ([IO.File]::ReadAllText($disablePath).Trim() -eq 'AnotherPlugin') 'Re-enable changed other disabled plugins'
    Assert ($launchRecord.Path -eq $exe -and $launchRecord.Count -eq 3) 'Recovery did not request the expected restarts'

    $bytes[0x84] = 0x4c; $bytes[0x85] = 0x01
    [IO.File]::WriteAllBytes($exe, $bytes)
    Expect-Failure { & $install -CloudMusicDir $appDir -MarketOnly } 'requires x64'
    $bytes[0x84] = 0x64; $bytes[0x85] = 0x86
    [IO.File]::WriteAllBytes($exe, $bytes)
    [IO.File]::AppendAllText((Join-Path $sandboxTools 'packages\PluginMarket.plugin'), 'corruption')
    Expect-Failure { & $install -CloudMusicDir $appDir -MarketOnly } 'checksum mismatch'
    Assert ((Get-FileHash -LiteralPath $exe).Hash -eq $exeHash) 'Executable changed'
    Assert ((Get-FileHash -LiteralPath $cef).Hash -eq $exeHash) 'CEF changed'
    Write-Output "PASS: isolated install/restore protections on PowerShell $($PSVersionTable.PSVersion)"
} finally {
    $env:BETTERNCM_PROFILE = $previousProfile
    # Resolve and check the exact generated target before recursive cleanup.
    $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolvedTestRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($resolvedTestRoot) -notmatch '^betterncm-install-test-[a-f0-9]{32}$') {
        throw 'Refusing cleanup outside the generated test directory.'
    }
    if (Test-Path -LiteralPath $resolvedTestRoot) { Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force }
}
