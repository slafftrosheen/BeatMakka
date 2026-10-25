param([string]$StudioExe, [switch]$InstallOnly)
$ErrorActionPreference = 'Stop'
if (-not $StudioExe) {
    $versions = Join-Path $env:LOCALAPPDATA 'Roblox/Versions'
    $StudioExe = Get-ChildItem -LiteralPath $versions -Directory |
        ForEach-Object { Join-Path $_.FullName 'RobloxStudioBeta.exe' } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Sort-Object { (Get-Item -LiteralPath $_).LastWriteTime } -Descending |
        Select-Object -First 1
}
if (-not $StudioExe -or -not (Test-Path -LiteralPath $StudioExe -PathType Leaf)) { throw 'Roblox Studio is not installed. Pass -StudioExe with its executable path.' }
$sourceRoot = Join-Path $PSScriptRoot 'content/needle-quay'
$manifestPath = Join-Path $PSScriptRoot 'install-manifest.json'
if (-not (Test-Path -LiteralPath $sourceRoot)) {
    $sourceRoot = Join-Path $PSScriptRoot '../../assets/local-demo/content/needle-quay'
    $manifestPath = Join-Path $PSScriptRoot '../../assets/local-demo/install-manifest.json'
}
$sourceRoot = [IO.Path]::GetFullPath($sourceRoot)
$destinationRoot = [IO.Path]::GetFullPath((Join-Path (Split-Path $StudioExe) 'content/needle-quay'))
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
foreach ($entry in $manifest.files) {
    $sourcePath = [IO.Path]::GetFullPath((Join-Path $sourceRoot $entry.file))
    $destinationPath = [IO.Path]::GetFullPath((Join-Path $destinationRoot $entry.file))
    if (-not $sourcePath.StartsWith($sourceRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        -not $destinationPath.StartsWith($destinationRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid package path.' }
    if ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Source checksum failed: $($entry.file)" }
    New-Item -ItemType Directory -Path (Split-Path $destinationPath) -Force | Out-Null
    if (-not (Test-Path -LiteralPath $destinationPath) -or (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash -ne $entry.sha256) {
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
    }
    if ((Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Installed checksum failed: $($entry.file)" }
}
Write-Host "Installed and verified $($manifest.files.Count) local Needle Quay files. No uploads."
if (-not $InstallOnly) {
    $place = Join-Path $PSScriptRoot 'NeedleQuay-Groovebox.rbxlx'
    if (-not (Test-Path -LiteralPath $place -PathType Leaf)) { throw 'NeedleQuay-Groovebox.rbxlx is missing.' }
    Start-Process -FilePath $StudioExe -ArgumentList ('"' + $place + '"') -WindowStyle Hidden
}
