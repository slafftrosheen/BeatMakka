param([string]$Python = 'python', [string]$EvidenceDir = 'docs/evidence/handoff-v4/groovebox-2026-10-30')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location -LiteralPath $projectRoot
try {
    $outputDirectory = Join-Path $projectRoot 'output/needle-quay-demo'
    $placePath = Join-Path $outputDirectory 'NeedleQuay-Groovebox-v4.rbxlx'
    $stagedPlace = Join-Path $outputDirectory 'NeedleQuay-Groovebox-v4.stage.rbxlx'
    if (Test-Path -LiteralPath ($placePath + '.lock')) { throw 'The final place has a Studio lock. Keep that session intact; rebuild only after it is closed normally.' }
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    & $Python tools/package_local_demo_content.py
    if ($LASTEXITCODE -ne 0) { throw 'Local content packaging failed.' }
    & $Python tools/build_sample_waveforms.py
    if ($LASTEXITCODE -ne 0) { throw 'Local sample waveform projection failed.' }
    # Run from the project root so Rokit resolves the pinned tool.
    & rojo build default.project.json --output $stagedPlace
    if ($LASTEXITCODE -ne 0) { throw 'Rojo build failed.' }
    if (Test-Path -LiteralPath ($placePath + '.lock')) { throw 'The final place was opened during the build. The staged build is retained; the live place was preserved.' }
    if (Test-Path -LiteralPath $placePath -PathType Leaf) {
        [IO.File]::Replace($stagedPlace, $placePath, $null)
    } else {
        [IO.File]::Move($stagedPlace, $placePath)
    }
    & $Python tools/package_needle_quay_demo.py --evidence-dir $EvidenceDir
    if ($LASTEXITCODE -ne 0) { throw 'Final package creation failed.' }
    Write-Host 'Final local demo: output/needle-quay-demo/NeedleQuay-Groovebox-v4.zip. No upload or publication.'
} finally {
    Pop-Location
}
