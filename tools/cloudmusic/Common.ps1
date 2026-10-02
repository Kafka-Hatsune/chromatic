# Shared by the Windows PowerShell 5.1 / PowerShell 7 entry points.
function Resolve-CloudMusicDirectory([string]$Directory) {
    if (!$Directory) {
        $candidates = @()
        $candidates += @(Get-Process cloudmusic -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Path) { Split-Path $_.Path }
        })
        foreach ($key in @(
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\cloudmusic.exe',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\cloudmusic.exe',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\cloudmusic.exe'
        )) {
            $value = (Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue).'(default)'
            if ($value) { $candidates += Split-Path ($value.Trim('"')) }
        }
        foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA)) {
            if ($base) { $candidates += Join-Path $base 'NetEase\CloudMusic' }
        }
        $candidates = @($candidates | Where-Object {
            Test-Path -LiteralPath (Join-Path $_ 'cloudmusic.exe') -PathType Leaf
        } | Sort-Object -Unique)
        if ($candidates.Count -eq 1) {
            $Directory = $candidates[0]
        } else {
            if ($candidates.Count) { Write-Host ('Detected installations: ' + ($candidates -join ', ')) }
            $Directory = Read-Host 'Enter the CloudMusic folder (or full cloudmusic.exe path)'
        }
    }
    if ([string]::IsNullOrWhiteSpace($Directory)) { throw 'Specify -CloudMusicDir.' }
    $Directory = $Directory.Trim().Trim('"')
    if ([IO.Path]::GetFileName($Directory) -ieq 'cloudmusic.exe') { $Directory = Split-Path $Directory }
    $resolved = (Resolve-Path -LiteralPath $Directory -ErrorAction Stop).ProviderPath
    if (!(Test-Path -LiteralPath (Join-Path $resolved 'cloudmusic.exe') -PathType Leaf)) {
        throw "cloudmusic.exe not found in: $resolved"
    }
    return $resolved
}

function Resolve-BetterNCMProfile([string]$Directory) {
    $configured = [Environment]::GetEnvironmentVariable('BETTERNCM_PROFILE')
    if (!$Directory) {
        if ($configured) { $Directory = $configured } else { $Directory = 'C:\betterncm' }
    }
    $resolved = [IO.Path]::GetFullPath($Directory)
    if ($resolved.TrimEnd('\') -eq [IO.Path]::GetPathRoot($resolved).TrimEnd('\')) {
        throw 'A drive root cannot be used as the BetterNCM profile.'
    }
    if ($configured) {
        if ([IO.Path]::GetFullPath($configured) -ne $resolved) {
            throw 'Use -ProfileDir matching the BETTERNCM_PROFILE environment variable.'
        }
    } elseif ($resolved -ne 'C:\betterncm') {
        throw 'Custom profiles require BETTERNCM_PROFILE in this process environment.'
    }
    return $resolved
}

function Get-PeMachine([string]$Path) {
    $reader = [IO.BinaryReader]::new([IO.File]::OpenRead($Path))
    try {
        if ($reader.ReadUInt16() -ne 0x5A4D) { throw "Invalid PE file: $Path" }
        $reader.BaseStream.Position = 0x3c
        $reader.BaseStream.Position = $reader.ReadInt32()
        if ($reader.ReadUInt32() -ne 0x4550) { throw "Invalid PE signature: $Path" }
        return $reader.ReadUInt16()
    } finally { $reader.Dispose() }
}

function Stop-TargetCloudMusic([string]$Exe, [bool]$Restart) {
    $running = @(Get-Process cloudmusic -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $Exe })
    if ($running.Count -and !$Restart) { throw 'Exit CloudMusic completely first, or pass -Restart.' }
    if ($running.Count) {
        $running | Stop-Process -Force
        foreach ($process in $running) {
            if (!$process.WaitForExit(10000)) { throw "CloudMusic process did not exit: $($process.Id)" }
        }
    }
}

function Write-Utf8File([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}
