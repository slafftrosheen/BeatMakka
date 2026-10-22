"""Attach production output paths to contracts without replacing accepted models."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "data/assets.json"
data = json.loads(path.read_text(encoding="utf-8"))
report = json.loads((ROOT / "docs/evidence/optimized-assets.json").read_text())
by_id = {a["id"]: a for a in report["assets"]}
for asset in data["assets"]:
    aid = asset["id"]
    if aid in by_id:
        asset["optimized_candidate"] = by_id[aid]["output"]
        asset["optimized_review"] = "New texture/UV/static-grouping variant; Blender re-import checked, art/Studio/runtime review pending. Accepted dcc_candidate remains unchanged."
        asset["optimization_evidence"] = "docs/evidence/optimized-assets.json"
    if aid in ("T01", "T02", "T03", "T04"):
        asset["source_deliverable"] = "assets/production/materials/layout.json"
        asset["status"] = "Shared source sets authored; Roblox map upload and PBR review pending"
    elif aid in ("G01", "G03", "G04"):
        asset["source_deliverable"] = "assets/production/graphics"
        asset["status"] = "Original source graphics authored; upload/Studio review pending"
    elif aid in ("U01", "U02", "U04"):
        asset["source_deliverable"] = "src/client/WorkshopView.luau"
        asset["status"] = "Implemented source; Studio touch/keyboard/gamepad/runtime review pending"
    elif aid in ("S01", "S02"):
        asset["source_deliverable"] = "assets/production/audio/manifest.json"
        asset["status"] = "Original synthesized source bank authored; listening, upload permissions and playback review pending"
    if aid in ("H06", "I02", "I03", "I04", "F01", "F03"):
        asset["runtime_implementation"] = "docs/WORKSHOP_MILESTONE.md"
        asset["runtime_status"] = "Implemented source; Studio/runtime acceptance pending"
path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("Registered 20 optimized variants and production source/runtime paths; accepted models preserved.")
