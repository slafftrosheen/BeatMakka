"""Map all 74 authored packages to concrete local sources, without promoting asset gates."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
registry = json.loads((ROOT / "data/assets.json").read_text(encoding="utf-8"))
records = []
for asset in registry["assets"]:
    key = asset["id"]
    if key.startswith("M") or key in ("P08", "P09", "P10", "P15", "W03", "W04"):
        sources = ["src/server/ModularKit.luau"]
        acceptance = "Source constructor; DCC/export/art/import gates separate"
    elif key in ("H01", "H06", "W01", "W02"):
        sources = ["src/server/WorldBuilder.luau"]
        acceptance = "Authored runtime assembly; navigation/visual acceptance separate"
    elif key in ("H02", "H03", "H04", "H05"):
        sources = ["src/server/AssetDetails.luau", "src/client/WorldFeedback.luau"]
        acceptance = "Functional bindings and articulated proxies; imported art gates separate"
    elif key.startswith("P"):
        sources = [asset["optimized_candidate"], "src/server/AssetSpawner.luau"]
        acceptance = "Existing candidate source and placement; art/import gates separate"
    elif key in ("I01", "I02", "I03"):
        sources = ["src/server/MusicService.luau", "src/client/WorldFeedback.luau"]
        acceptance = "Server unlock/preview binding; audio permission gate separate"
    elif key == "I04":
        sources = ["src/client/Restoration.luau", "src/client/WorldFeedback.luau"]
        acceptance = "Personal four-state restoration; art gate separate"
    elif key == "I05":
        sources = ["src/server/ListeningSession.luau"]
        acceptance = "Snapshot/session ownership; visual/audio acceptance separate"
    elif key.startswith(("T", "G")):
        sources = ["tools/build_content_sources.py", "assets/production/source-manifest.json"]
        acceptance = "Original editable/generator sources; upload/art gates separate"
    elif key.startswith("A"):
        sources = ["src/shared/MotionPoses.luau", "src/client/WorldFeedback.luau"]
        acceptance = "Local rigid transform reactions; candidate rig/art review separate"
    elif key.startswith("F"):
        sources = ["src/shared/LightingPresets.luau", "src/client/WorldFeedback.luau", "src/client/Restoration.luau"]
        acceptance = "Local optional presentation; visual/performance acceptance separate"
    elif key.startswith("U"):
        sources = ["src/client/ListeningView.luau" if key == "U03" else "src/client/WorkshopView.luau"]
        acceptance = "Native responsive controls and state feedback; device checks recorded separately"
    elif key.startswith("S"):
        sources = ["assets/production/audio/manifest.json", "src/client/AudioEngine.luau"]
        acceptance = "Original WAV sources and runtime binding; audio uploads/listening remain open"
    else:
        raise ValueError("Unmapped canonical ID: " + key)
    missing = [s for s in sources if not (ROOT / s).is_file()]
    if missing:
        raise ValueError(f"Missing {key} sources: {missing}")
    records.append({"id": key, "name": asset["name"], "sources": sources, "boundary": acceptance})

output = {"date": "2026-10-22", "source_mapped": len(records), "total": len(registry["assets"]),
          "meaning": "File-level implementation traceability, not 100 percent asset or runtime acceptance",
          "packages": records}
(ROOT / "docs/evidence/implementation-coverage.json").write_text(json.dumps(output, indent=2) + "\n")
lines = ["# First-zone implementation coverage", "",
         "All 74 canonical packages have concrete local source mappings. This is source coverage, not a claim that assets, devices, audio, cloud storage or published delivery passed acceptance.", "",
         "The v0.2 PDFs govern the playable direction. The register's authored constraints remain preserved; W01's newer 12 x 8 prototype stage is recorded separately.", "",
         "| ID | Package | Sources | Acceptance boundary |", "| --- | --- | --- | --- |"]
for row in records:
    paths = ", ".join(f"[`{s}`](../{s})" for s in row["sources"])
    lines.append(f"| {row['id']} | {row['name']} | {paths} | {row['boundary']} |")
lines += ["", "See [runtime results](RUNTIME_VERIFICATION.md) for actual checks, failures/fixes and remaining acceptance. No asset pipeline stage is inferred from this table."]
(ROOT / "docs/IMPLEMENTATION_COVERAGE.md").write_text("\n".join(lines) + "\n")
print(json.dumps({"source_mapped": len(records), "total": len(registry["assets"])}))
