param([string]$StudioExe, [switch]$InstallOnly, [string]$Place = 'NeedleQuay-Groovebox-v4.rbxlx')
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
if (-not (Test-Path -LiteralPath $sourceRoot)) {
    $sourceRoot = Join-Path $PSScriptRoot '../assets/local-demo/content/needle-quay'
    $manifestPath = Join-Path $PSScriptRoot '../assets/local-demo/install-manifest.json'
}
$sourceRoot = [IO.Path]::GetFullPath($sourceRoot)
$destinationRoot = [IO.Path]::GetFullPath((Join-Path (Split-Path $StudioExe) 'content/needle-quay'))
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.version -lt 2 -or $manifest.namespace -ne 'needle-quay' -or -not $manifest.active_content_sha256) { throw 'This package predates audio retirement. Rebuild the current package.' }
$authorityPath = Join-Path (Split-Path $manifestPath) 'active-content.json'
if (-not (Test-Path -LiteralPath $authorityPath -PathType Leaf) -or
    (Get-FileHash -LiteralPath $authorityPath -Algorithm SHA256).Hash -ne $manifest.active_content_sha256) { throw 'Active content authority is missing or stale. Rebuild the current package.' }
$allowedAudio = @($manifest.allowed_audio_files | Sort-Object)
$packagedAudio = @($manifest.files | Where-Object { $_.file.StartsWith('audio/') } | ForEach-Object { $_.file } | Sort-Object)
if (Compare-Object -ReferenceObject $allowedAudio -DifferenceObject $packagedAudio) { throw 'Packaged audio differs from its active allowlist.' }
$authority = Get-Content -LiteralPath $authorityPath -Raw | ConvertFrom-Json
$allowedPreviews = @($manifest.allowed_preview_audio_files | Sort-Object)
$expectedPreviews = @($authority.local_preview_audio | ForEach-Object { 'preview-audio/' + $_.id + '.wav' } | Sort-Object)
$packagedPreviews = @($manifest.files | Where-Object { $_.file.StartsWith('preview-audio/') } | ForEach-Object { $_.file } | Sort-Object)
if (($allowedPreviews -join "`n") -ne ($expectedPreviews -join "`n") -or
    ($packagedPreviews -join "`n") -ne ($expectedPreviews -join "`n")) { throw 'Packaged previews differ from their explicit local audition allowlist.' }
foreach ($preview in $authority.local_preview_audio) {
    if ($preview.audio_approved -ne $false -or $preview.runtime_admitted -ne $false -or
        $preview.listening_review -ne 'pending') { throw 'A local preview cannot claim musical approval or admission.' }
}
foreach ($entry in $manifest.retired_audio_payloads) {
    if ($entry.file -notmatch '^audio/[a-z0-9_.]+\.wav$') { throw 'Invalid retired audio path.' }
    $retiredPath = [IO.Path]::GetFullPath((Join-Path $destinationRoot $entry.file))
    if (-not $retiredPath.StartsWith($destinationRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Retirement path outside namespace.' }
    if ((Test-Path -LiteralPath $retiredPath -PathType Leaf) -and (Get-FileHash -LiteralPath $retiredPath -Algorithm SHA256).Hash -eq $entry.sha256) {
        Remove-Item -LiteralPath $retiredPath
    }
}
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
    if ([IO.Path]::GetFileName($Place) -ne $Place -or [IO.Path]::GetExtension($Place) -ne '.rbxlx') { throw 'Choose a package .rbxlx filename.' }
    $placePath = Join-Path $PSScriptRoot $Place
    if (-not (Test-Path -LiteralPath $placePath -PathType Leaf)) { $placePath = Join-Path $PSScriptRoot "../output/needle-quay-demo/$Place" }
    if (-not (Test-Path -LiteralPath $placePath -PathType Leaf)) { throw "$Place is missing. Run tools/build_current_demo.ps1 first." }
    Start-Process -FilePath $StudioExe -ArgumentList ('"' + [IO.Path]::GetFullPath($placePath) + '"') -WindowStyle Normal
}
